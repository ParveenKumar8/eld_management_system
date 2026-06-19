import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

export interface FleetPushPayload {
  type: string;
  title: string;
  body: string;
  detail?: string;
  route?: string;
}

@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private initialized = false;

  constructor(private readonly config: ConfigService) {
    this.tryInitialize();
  }

  get isEnabled() {
    return this.initialized;
  }

  async sendToTokens(tokens: string[], payload: FleetPushPayload) {
    if (!tokens.length) {
      return { sent: 0, failed: 0, skipped: 0, mode: 'no_tokens' as const };
    }

    if (!this.initialized) {
      this.logger.warn(
        `FCM disabled — would push "${payload.type}" to ${tokens.length} device(s)`,
      );
      return {
        sent: 0,
        failed: 0,
        skipped: tokens.length,
        mode: 'fcm_disabled' as const,
      };
    }

    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        type: payload.type,
        title: payload.title,
        body: payload.body,
        ...(payload.detail ? { detail: payload.detail } : {}),
        ...(payload.route ? { route: payload.route } : {}),
      },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    return {
      sent: response.successCount,
      failed: response.failureCount,
      skipped: 0,
      mode: 'fcm' as const,
    };
  }

  private tryInitialize() {
    if (admin.apps.length > 0) {
      this.initialized = true;
      return;
    }

    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
    if (!projectId) {
      this.logger.warn('FIREBASE_PROJECT_ID not set — fleet push sender disabled');
      return;
    }

    try {
      const credentialsPath = this.config.get<string>('GOOGLE_APPLICATION_CREDENTIALS');
      const inlineJson = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');

      if (inlineJson) {
        const credential = admin.credential.cert(JSON.parse(inlineJson));
        admin.initializeApp({ credential, projectId });
      } else if (credentialsPath) {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
          projectId,
        });
      } else {
        admin.initializeApp({ projectId });
      }

      this.initialized = true;
      this.logger.log(`FCM initialized for project ${projectId}`);
    } catch (error) {
      this.logger.error('FCM initialization failed', error as Error);
    }
  }
}