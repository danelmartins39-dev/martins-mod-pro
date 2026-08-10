import { query } from './database.js';
import { hashSHA256, generateLicenseKey, calculateExpirationDate, isExpired } from './crypto.js';
import { License, ActivateResponse, CheckResponse } from './types.js';

export class LicenseService {
  /**
   * Gera uma nova chave de licença
   */
  async generateLicense(durationDays: number): Promise<string> {
    const key = generateLicenseKey();
    const keyHash = hashSHA256(key);

    await query(
      `INSERT INTO licenses (keyHash, durationDays, status, createdAt, updatedAt)
       VALUES ($1, $2, $3, NOW(), NOW())`,
      [keyHash, durationDays, 'ACTIVE']
    );

    return key;
  }

  /**
   * Ativa uma licença vinculando ao dispositivo
   */
  async activateLicense(key: string, deviceId: string, appVersion: string, osVersion: string): Promise<ActivateResponse> {
    const keyHash = hashSHA256(key);
    const deviceHash = hashSHA256(deviceId);

    const result = await query(
      `SELECT * FROM licenses WHERE keyHash = $1`,
      [keyHash]
    );

    if (result.rows.length === 0) {
      return {
        valid: false,
        status: 'NOT_FOUND',
        error: 'LICENSE_NOT_FOUND',
      };
    }

    const license: License = result.rows[0];

    if (license.status === 'REVOKED') {
      return {
        valid: false,
        status: 'REVOKED',
        error: 'LICENSE_REVOKED',
      };
    }

    if (license.status === 'EXPIRED') {
      return {
        valid: false,
        status: 'EXPIRED',
        error: 'LICENSE_EXPIRED',
      };
    }

    // Se já foi ativada, verifica se é o mesmo dispositivo
    if (license.activatedAt) {
      if (license.deviceHash !== deviceHash) {
        return {
          valid: false,
          status: 'NOT_FOUND',
          error: 'DEVICE_MISMATCH',
        };
      }

      // Atualiza última verificação
      await query(
        `UPDATE licenses SET lastCheckedAt = NOW() WHERE id = $1`,
        [license.id]
      );

      const remainingSeconds = Math.floor((new Date(license.expiresAt!).getTime() - Date.now()) / 1000);

      return {
        valid: true,
        status: 'ACTIVE',
        expiresAt: license.expiresAt?.toISOString(),
        remainingSeconds: Math.max(0, remainingSeconds),
      };
    }

    // Primeira ativação
    const now = new Date();
    const expiresAt = calculateExpirationDate(now, license.durationDays);

    await query(
      `UPDATE licenses 
       SET activatedAt = $1, expiresAt = $2, deviceHash = $3, appVersion = $4, osVersion = $5, lastCheckedAt = NOW(), updatedAt = NOW()
       WHERE id = $6`,
      [now, expiresAt, deviceHash, appVersion, osVersion, license.id]
    );

    const remainingSeconds = Math.floor((expiresAt.getTime() - Date.now()) / 1000);

    return {
      valid: true,
      status: 'ACTIVE',
      expiresAt: expiresAt.toISOString(),
      remainingSeconds,
    };
  }

  /**
   * Verifica se uma licença é válida
   */
  async checkLicense(key: string, deviceId: string): Promise<CheckResponse> {
    const keyHash = hashSHA256(key);
    const deviceHash = hashSHA256(deviceId);

    const result = await query(
      `SELECT * FROM licenses WHERE keyHash = $1`,
      [keyHash]
    );

    if (result.rows.length === 0) {
      return {
        valid: false,
        status: 'NOT_FOUND',
        error: 'LICENSE_NOT_FOUND',
      };
    }

    const license: License = result.rows[0];

    // Atualiza última verificação
    await query(
      `UPDATE licenses SET lastCheckedAt = NOW() WHERE id = $1`,
      [license.id]
    );

    if (license.status === 'REVOKED') {
      return {
        valid: false,
        status: 'REVOKED',
        error: 'LICENSE_REVOKED',
      };
    }

    if (!license.activatedAt) {
      return {
        valid: false,
        status: 'NOT_FOUND',
        error: 'LICENSE_NOT_FOUND',
      };
    }

    if (license.deviceHash !== deviceHash) {
      return {
        valid: false,
        status: 'DEVICE_MISMATCH',
        error: 'DEVICE_MISMATCH',
      };
    }

    if (isExpired(new Date(license.expiresAt!))) {
      // Atualiza status para EXPIRED
      await query(
        `UPDATE licenses SET status = $1, updatedAt = NOW() WHERE id = $2`,
        ['EXPIRED', license.id]
      );

      return {
        valid: false,
        status: 'EXPIRED',
        error: 'LICENSE_EXPIRED',
      };
    }

    const remainingSeconds = Math.floor((new Date(license.expiresAt!).getTime() - Date.now()) / 1000);

    return {
      valid: true,
      status: 'ACTIVE',
      expiresAt: license.expiresAt?.toISOString(),
      remainingSeconds: Math.max(0, remainingSeconds),
    };
  }

  /**
   * Revoga uma licença
   */
  async revokeLicense(key: string): Promise<boolean> {
    const keyHash = hashSHA256(key);

    const result = await query(
      `UPDATE licenses SET status = $1, updatedAt = NOW() WHERE keyHash = $2 RETURNING id`,
      ['REVOKED', keyHash]
    );

    return result.rows.length > 0;
  }

  /**
   * Reativa uma licença
   */
  async reactivateLicense(key: string): Promise<boolean> {
    const keyHash = hashSHA256(key);

    const result = await query(
      `UPDATE licenses SET status = $1, updatedAt = NOW() WHERE keyHash = $2 RETURNING id`,
      ['ACTIVE', keyHash]
    );

    return result.rows.length > 0;
  }

  /**
   * Obtém informações de uma licença
   */
  async getLicenseInfo(key: string): Promise<License | null> {
    const keyHash = hashSHA256(key);

    const result = await query(
      `SELECT * FROM licenses WHERE keyHash = $1`,
      [keyHash]
    );

    return result.rows.length > 0 ? result.rows[0] : null;
  }

  /**
   * Lista todas as licenças
   */
  async listLicenses(): Promise<License[]> {
    const result = await query(
      `SELECT * FROM licenses ORDER BY createdAt DESC`
    );

    return result.rows;
  }

  /**
   * Deleta uma licença
   */
  async deleteLicense(key: string): Promise<boolean> {
    const keyHash = hashSHA256(key);

    const result = await query(
      `DELETE FROM licenses WHERE keyHash = $1 RETURNING id`,
      [keyHash]
    );

    return result.rows.length > 0;
  }
}

export default new LicenseService();
