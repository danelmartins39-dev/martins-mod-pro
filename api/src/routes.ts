import { Router, Request, Response } from 'express';
import licenseService from './licenseService.js';
import { ActivateRequest, CheckRequest, DeactivateRequest } from './types.js';

const router = Router();

/**
 * POST /api/license/activate
 * Ativa uma licença vinculando ao dispositivo
 */
router.post('/api/license/activate', async (req: Request, res: Response) => {
  try {
    const { key, deviceId, appVersion, osVersion } = req.body as ActivateRequest;

    if (!key || !deviceId || !appVersion || !osVersion) {
      return res.status(400).json({
        valid: false,
        status: 'NOT_FOUND',
        error: 'Missing required fields',
      });
    }

    const response = await licenseService.activateLicense(key, deviceId, appVersion, osVersion);
    res.json(response);
  } catch (error) {
    console.error('Error in /api/license/activate:', error);
    res.status(500).json({
      valid: false,
      status: 'NOT_FOUND',
      error: 'Internal server error',
    });
  }
});

/**
 * POST /api/license/check
 * Verifica se uma licença é válida
 */
router.post('/api/license/check', async (req: Request, res: Response) => {
  try {
    const { key, deviceId } = req.body as CheckRequest;

    if (!key || !deviceId) {
      return res.status(400).json({
        valid: false,
        status: 'NOT_FOUND',
        error: 'Missing required fields',
      });
    }

    const response = await licenseService.checkLicense(key, deviceId);
    res.json(response);
  } catch (error) {
    console.error('Error in /api/license/check:', error);
    res.status(500).json({
      valid: false,
      status: 'NOT_FOUND',
      error: 'Internal server error',
    });
  }
});

/**
 * POST /api/license/deactivate
 * Desativa uma licença
 */
router.post('/api/license/deactivate', async (req: Request, res: Response) => {
  try {
    const { key } = req.body as DeactivateRequest;

    if (!key) {
      return res.status(400).json({
        success: false,
        message: 'Missing key',
      });
    }

    const success = await licenseService.revokeLicense(key);

    res.json({
      success,
      message: success ? 'License deactivated' : 'License not found',
    });
  } catch (error) {
    console.error('Error in /api/license/deactivate:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
});

/**
 * GET /health
 * Health check endpoint
 */
router.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

export default router;
