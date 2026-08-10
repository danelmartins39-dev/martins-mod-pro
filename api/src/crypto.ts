import crypto from 'crypto';

/**
 * Gera um hash SHA-256 de uma string
 */
export function hashSHA256(input: string): string {
  return crypto.createHash('sha256').update(input).digest('hex');
}

/**
 * Gera uma chave de licença aleatória
 * Formato: XXXX-XXXX-XXXX-XXXX (16 caracteres + 3 hífens)
 */
export function generateLicenseKey(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let key = '';
  for (let i = 0; i < 16; i++) {
    key += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `${key.slice(0, 4)}-${key.slice(4, 8)}-${key.slice(8, 12)}-${key.slice(12, 16)}`;
}

/**
 * Valida o formato de uma chave de licença
 */
export function isValidKeyFormat(key: string): boolean {
  const keyRegex = /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
  return keyRegex.test(key);
}

/**
 * Valida o período de duração
 */
export function isValidDuration(days: number): boolean {
  return [1, 3, 7, 15, 30].includes(days);
}

/**
 * Calcula a data de expiração
 */
export function calculateExpirationDate(activatedAt: Date, durationDays: number): Date {
  const expiresAt = new Date(activatedAt);
  expiresAt.setDate(expiresAt.getDate() + durationDays);
  return expiresAt;
}

/**
 * Verifica se uma data expirou
 */
export function isExpired(expiresAt: Date): boolean {
  return new Date() > expiresAt;
}
