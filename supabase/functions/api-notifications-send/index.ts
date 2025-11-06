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
    const notificationService = new NotificationService(serviceClient)
    
    const body = await req.json()
    const {
      user_id,
      type,
      title,
      body: bodyText,
      data,
      channels
    } = body

    // Validate required fields
    if (!user_id || !type || !title || !bodyText) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, type, title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Send notification
    const results = await notificationService.sendNotification({
      userId: user_id,
      type,
      title,
      body: bodyText,
      data,
      channels
    })

    return new Response(
      JSON.stringify({
        success: true,
        results
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Notification send error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

