import { query, closePool } from './database.js';

const migrations = [
  `
    CREATE TABLE IF NOT EXISTS licenses (
      id SERIAL PRIMARY KEY,
      keyHash VARCHAR(64) NOT NULL UNIQUE,
      durationDays INTEGER NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
      createdAt TIMESTAMP NOT NULL DEFAULT NOW(),
      activatedAt TIMESTAMP,
      expiresAt TIMESTAMP,
      deviceHash VARCHAR(64),
      lastCheckedAt TIMESTAMP,
      appVersion VARCHAR(32),
      osVersion VARCHAR(32),
      updatedAt TIMESTAMP NOT NULL DEFAULT NOW()
    );
  `,
  `
    CREATE INDEX IF NOT EXISTS idx_licenses_keyHash ON licenses(keyHash);
  `,
  `
    CREATE INDEX IF NOT EXISTS idx_licenses_status ON licenses(status);
  `,
  `
    CREATE INDEX IF NOT EXISTS idx_licenses_deviceHash ON licenses(deviceHash);
  `,
];

async function runMigrations() {
  try {
    console.log('Running migrations...');

    for (const migration of migrations) {
      await query(migration);
      console.log('✓ Migration executed');
    }

    console.log('✓ All migrations completed successfully');
    await closePool();
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    await closePool();
    process.exit(1);
  }
}

runMigrations();
