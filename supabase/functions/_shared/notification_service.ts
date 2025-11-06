// Notification service with push/SMS stubs
// Supports feature flags for enabling/disabling notification channels

interface NotificationPreferences {
  push_enabled: boolean
  sms_enabled: boolean
  email_enabled: boolean
  job_status_enabled: boolean
  document_reminders_enabled: boolean
}

interface NotificationData {
  userId: string
  type: string
  title: string
  body: string
  data?: Record<string, any>
  channels?: ('push' | 'sms' | 'email' | 'in_app')[]
}

interface NotificationResult {
  success: boolean
  channel: string
  external_id?: string
  error?: string
}

export class NotificationService {
  private serviceClient: any
  private pushEnabled: boolean
  private smsEnabled: boolean
  private emailEnabled: boolean

  constructor(serviceClient: any) {
    this.serviceClient = serviceClient
    
    // Feature flags from environment
    this.pushEnabled = Deno.env.get('ENABLE_PUSH_NOTIFICATIONS') === 'true'
    this.smsEnabled = Deno.env.get('ENABLE_SMS_NOTIFICATIONS') === 'true'
    this.emailEnabled = Deno.env.get('ENABLE_EMAIL_NOTIFICATIONS') === 'true'
  }

  /**
   * Send notification to user
   */
  async sendNotification(
    notification: NotificationData
  ): Promise<NotificationResult[]> {
    const results: NotificationResult[] = []
    
    // Get user preferences
    const preferences = await this.getUserPreferences(notification.userId)
    
    // Determine channels to use
    const channels = notification.channels || ['in_app']
    
    // Always create in-app notification
    const inAppNotification = await this.createInAppNotification(notification)
    
    // Send to each channel based on preferences and feature flags
    for (const channel of channels) {
      if (channel === 'in_app') {
        results.push({
          success: true,
          channel: 'in_app',
          external_id: inAppNotification.id
        })
        continue
      }
      
      // Check if channel is enabled via feature flag
      if (!this.isChannelEnabled(channel)) {
        console.log(`Channel ${channel} is disabled via feature flag`)
        continue
      }
      
      // Check user preferences
      if (!this.shouldSendToChannel(preferences, notification.type, channel)) {
        console.log(`User ${notification.userId} has disabled ${channel} for ${notification.type}`)
        continue
      }
      
      try {
        let result: NotificationResult
        
        switch (channel) {
          case 'push':
            result = await this.sendPushNotification(notification, inAppNotification.id)
            break
          case 'sms':
            result = await this.sendSMSNotification(notification, inAppNotification.id)
            break
          case 'email':
            result = await this.sendEmailNotification(notification, inAppNotification.id)
            break
          default:
            result = { success: false, channel, error: 'Unknown channel' }
        }
        
        results.push(result)
      } catch (error) {
        console.error(`Error sending ${channel} notification:`, error)
        results.push({
          success: false,
          channel,
          error: error.message
        })
      }
    }
    
    return results
  }

  /**
   * Create in-app notification
   */
  private async createInAppNotification(
    notification: NotificationData
  ): Promise<any> {
    const { data, error } = await this.serviceClient
      .from('notifications')
      .insert({
        user_id: notification.userId,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        data: notification.data || {},
        channel: 'in_app',
        status: 'sent'
      })
      .select()
      .single()
    
    if (error) throw error
    return data
  }

  /**
   * Send push notification (FCM stub)
   */
  private async sendPushNotification(
    notification: NotificationData,
    notificationId: string
  ): Promise<NotificationResult> {
    // Get user's device tokens
    const { data: tokens } = await this.serviceClient
      .from('user_device_tokens')
      .select('device_token, platform')
      .eq('user_id', notification.userId)
    
    if (!tokens || tokens.length === 0) {
      return {
        success: false,
        channel: 'push',
        error: 'No device tokens found'
      }
    }
    
    // Stub: In production, this would call FCM API
    // For now, we'll log the notification
    console.log('[PUSH STUB] Sending push notification:', {
      userId: notification.userId,
      tokens: tokens.map((t: any) => t.device_token),
      title: notification.title,
      body: notification.body,
      data: notification.data
    })
    
    // In production:
    // const fcmApiKey = Deno.env.get('FCM_API_KEY')
    // const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    //   method: 'POST',
    //   headers: {
    //     'Authorization': `key=${fcmApiKey}`,
    //     'Content-Type': 'application/json'
    //   },
    //   body: JSON.stringify({
    //     registration_ids: tokens.map(t => t.device_token),
    //     notification: {
    //       title: notification.title,
    //       body: notification.body
    //     },
    //     data: notification.data
    //   })
    // })
    
    // Update notification with external ID (stub)
    const externalId = `fcm_${Date.now()}_${notificationId.substring(0, 8)}`
    
    await this.serviceClient
      .from('notifications')
      .update({
        external_id: externalId,
        sent_at: new Date().toISOString(),
        status: 'sent'
      })
      .eq('id', notificationId)
    
    return {
      success: true,
      channel: 'push',
      external_id: externalId
    }
  }

  /**
   * Send SMS notification (Twilio stub)
   */
  private async sendSMSNotification(
    notification: NotificationData,
    notificationId: string
  ): Promise<NotificationResult> {
    // Get user's phone number
    const { data: phone } = await this.serviceClient
      .from('user_phone_numbers')
      .select('phone_number')
      .eq('user_id', notification.userId)
      .eq('verified', true)
      .single()
    
    if (!phone) {
      return {
        success: false,
        channel: 'sms',
        error: 'No verified phone number found'
      }
    }
    
    // Stub: In production, this would call Twilio API
    // For now, we'll log the notification
    console.log('[SMS STUB] Sending SMS notification:', {
      userId: notification.userId,
      phoneNumber: phone.phone_number,
      body: `${notification.title}: ${notification.body}`
    })
    
    // In production:
    // const accountSid = Deno.env.get('TWILIO_ACCOUNT_SID')
    // const authToken = Deno.env.get('TWILIO_AUTH_TOKEN')
    // const fromNumber = Deno.env.get('TWILIO_PHONE_NUMBER')
    // const response = await fetch(
    //   `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
    //   {
    //     method: 'POST',
    //     headers: {
    //       'Authorization': `Basic ${btoa(`${accountSid}:${authToken}`)}`,
    //       'Content-Type': 'application/x-www-form-urlencoded'
    //     },
    //     body: new URLSearchParams({
    //       From: fromNumber,
    //       To: phone.phone_number,
    //       Body: `${notification.title}: ${notification.body}`
    //     })
    //   }
    // )
    
    // Update notification with external ID (stub)
    const externalId = `twilio_${Date.now()}_${notificationId.substring(0, 8)}`
    
    await this.serviceClient
      .from('notifications')
      .update({
        external_id: externalId,
        sent_at: new Date().toISOString(),
        status: 'sent'
      })
      .eq('id', notificationId)
    
    return {
      success: true,
      channel: 'sms',
      external_id: externalId
    }
  }

  /**
   * Send email notification (stub)
   */
  private async sendEmailNotification(
    notification: NotificationData,
    notificationId: string
  ): Promise<NotificationResult> {
    // Stub: In production, this would call email service (SendGrid, SES, etc.)
    console.log('[EMAIL STUB] Sending email notification:', {
      userId: notification.userId,
      title: notification.title,
      body: notification.body
    })
    
    // Update notification
    const externalId = `email_${Date.now()}_${notificationId.substring(0, 8)}`
    
    await this.serviceClient
      .from('notifications')
      .update({
        external_id: externalId,
        sent_at: new Date().toISOString(),
        status: 'sent'
      })
      .eq('id', notificationId)
    
    return {
      success: true,
      channel: 'email',
      external_id: externalId
    }
  }

  /**
   * Get user notification preferences
   */
  private async getUserPreferences(userId: string): Promise<NotificationPreferences> {
    const { data } = await this.serviceClient
      .from('user_notification_preferences')
      .select('*')
      .eq('user_id', userId)
      .single()
    
    // Return defaults if no preferences exist
    if (!data) {
      return {
        push_enabled: true,
        sms_enabled: false,
        email_enabled: true,
        job_status_enabled: true,
        document_reminders_enabled: true,
        marketing_enabled: false
      }
    }
    
    return data
  }

  /**
   * Check if channel is enabled via feature flag
   */
  private isChannelEnabled(channel: string): boolean {
    switch (channel) {
      case 'push':
        return this.pushEnabled
      case 'sms':
        return this.smsEnabled
      case 'email':
        return this.emailEnabled
      default:
        return false
    }
  }

  /**
   * Check if we should send to channel based on preferences
   */
  private shouldSendToChannel(
    preferences: NotificationPreferences,
    notificationType: string,
    channel: string
  ): boolean {
    // Check channel-specific preference
    switch (channel) {
      case 'push':
        if (!preferences.push_enabled) return false
        break
      case 'sms':
        if (!preferences.sms_enabled) return false
        break
      case 'email':
        if (!preferences.email_enabled) return false
        break
    }
    
    // Check type-specific preferences
    if (notificationType === 'document_expiry' || notificationType === 'document_expired') {
      return preferences.document_reminders_enabled
    }
    
    if (notificationType.startsWith('job_')) {
      return preferences.job_status_enabled
    }
    
    return true
  }
}

