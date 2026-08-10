export interface License {
  id: number;
  keyHash: string;
  durationDays: number;
  status: 'ACTIVE' | 'EXPIRED' | 'REVOKED';
  createdAt: Date;
  activatedAt: Date | null;
  expiresAt: Date | null;
  deviceHash: string | null;
  lastCheckedAt: Date | null;
  appVersion: string | null;
  osVersion: string | null;
  updatedAt: Date;
}

export interface ActivateRequest {
  key: string;
  deviceId: string;
  appVersion: string;
  osVersion: string;
}

export interface ActivateResponse {
  valid: boolean;
  status: 'ACTIVE' | 'EXPIRED' | 'REVOKED' | 'NOT_FOUND';
  expiresAt?: string;
  remainingSeconds?: number;
  error?: string;
}

export interface CheckRequest {
  key: string;
  deviceId: string;
}

export interface CheckResponse {
  valid: boolean;
  status: 'ACTIVE' | 'EXPIRED' | 'REVOKED' | 'NOT_FOUND' | 'DEVICE_MISMATCH';
  expiresAt?: string;
  remainingSeconds?: number;
  error?: string;
}

export interface DeactivateRequest {
  key: string;
}

export interface DeactivateResponse {
  success: boolean;
  message: string;
}

export interface TelegramUser {
  id: number;
  isAdmin: boolean;
}
