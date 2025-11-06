import { createServiceClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { NotificationService } from '../_shared/notification_service.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    const serviceClient = createServiceClient()
    
    // Call the SQL function to check for expiring documents
    const { data: reminderResult, error: reminderError } = await serviceClient
      .rpc('send_document_expiry_reminders')
    
    if (reminderError) {
      throw reminderError
    }

    // Get pending notifications for expiring documents
    const { data: pendingNotifications, error: notifError } = await serviceClient
      .from('notifications')
      .select('*')
      .eq('type', 'document_expiry')
      .eq('status', 'pending')
      .order('created_at', { ascending: true })
    
    if (notifError) {
      throw notifError
    }

    // Send notifications via notification service
    const notificationService = new NotificationService(serviceClient)
    const results = []

    if (pendingNotifications && pendingNotifications.length > 0) {
      for (const notif of pendingNotifications) {
        const sendResults = await notificationService.sendNotification({
          userId: notif.user_id,
          type: notif.type,
          title: notif.title,
          body: notif.body,
          data: notif.data,
          channels: ['in_app', 'push', 'email'] // Send to multiple channels
        })
        
        results.push({
          notification_id: notif.id,
          results: sendResults
        })
      }
    }

    // Process demotion notices
    const { data: demotionResult, error: demotionError } = await serviceClient
      .rpc('process_document_expiry_demotions')
    
    if (demotionError) {
      console.error('Demotion notices error:', demotionError)
    }

    // Get pending demotion notifications
    const { data: demotionNotifications, error: demotionNotifError } = await serviceClient
      .from('notifications')
      .select('*')
      .eq('type', 'document_expired')
      .eq('status', 'pending')
      .like('title', '%verification status%')
      .order('created_at', { ascending: true })
    
    if (demotionNotifications && demotionNotifications.length > 0) {
      for (const notif of demotionNotifications) {
        const sendResults = await notificationService.sendNotification({
          userId: notif.user_id,
          type: notif.type,
          title: notif.title,
          body: notif.body,
          data: notif.data,
          channels: ['in_app', 'push', 'email']
        })
        
        results.push({
          notification_id: notif.id,
          results: sendResults
        })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        reminders_checked: reminderResult?.documents_checked || 0,
        reminders_sent: reminderResult?.reminders_sent || 0,
        notifications_processed: results.length,
        demotion_notices: demotionResult?.notices_sent || 0,
        results
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Expiry reminders error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

