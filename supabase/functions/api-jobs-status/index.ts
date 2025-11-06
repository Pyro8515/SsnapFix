import { createDbClient, createServiceClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { NotificationService } from '../_shared/notification_service.ts'

Deno.serve(async (req) => {
  // Handle CORS preflight
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
    const supabase = createDbClient(req)
    const serviceClient = createServiceClient()

    // Get authenticated user
    const {
      data: { user: authUser },
      error: userError,
    } = await supabase.auth.getUser()

    if (userError || !authUser) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get app user
    const { data: userData, error: userDataError } = await supabase
      .from('users')
      .select('id, active_role')
      .eq('id', authUser.id)
      .single()

    if (userDataError || !userData) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get job ID from URL
    const url = new URL(req.url)
    const jobIdMatch = url.pathname.match(/\/api-jobs-status\/([^/]+)/)
    const jobId = jobIdMatch ? jobIdMatch[1] : null

    if (!jobId) {
      return new Response(
        JSON.stringify({ error: 'Missing job_id in URL' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body = await req.json()
    const { status: newStatus, location } = body

    // Validate status
    const validStatuses = ['en_route', 'arrived', 'started', 'completed', 'cancelled']
    if (!newStatus || !validStatuses.includes(newStatus)) {
      return new Response(
        JSON.stringify({ error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get job
    const { data: job, error: jobError } = await serviceClient
      .from('jobs')
      .select('*, customer:customer_id(id, phone, full_name), pro:assigned_pro_id(id, phone, full_name)')
      .eq('id', jobId)
      .single()

    if (jobError || !job) {
      return new Response(
        JSON.stringify({ error: 'Job not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify user has permission (customer or assigned pro)
    const isCustomer = job.customer_id === userData.id
    const isPro = job.assigned_pro_id === userData.id
    const isAdmin = false // TODO: Check admin status

    if (!isCustomer && !isPro && !isAdmin) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized to update this job' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate status transitions
    const currentStatus = job.status
    const validTransitions: Record<string, string[]> = {
      'requested': ['cancelled'],
      'assigned': ['en_route', 'cancelled'],
      'en_route': ['arrived', 'cancelled'],
      'arrived': ['started', 'cancelled'],
      'started': ['completed', 'cancelled'],
      'completed': [],
      'cancelled': [],
    }

    if (!validTransitions[currentStatus]?.includes(newStatus)) {
      return new Response(
        JSON.stringify({ 
          error: `Invalid status transition from ${currentStatus} to ${newStatus}`,
          valid_next: validTransitions[currentStatus] || []
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create location point if provided
    let locationPoint = null
    if (location && location.lat && location.lng) {
      locationPoint = `POINT(${location.lng} ${location.lat})`
      
      // Update pro's current location if they're moving
      if (isPro && (newStatus === 'en_route' || newStatus === 'arrived')) {
        await serviceClient
          .from('professional_profiles')
          .update({ current_location: locationPoint })
          .eq('user_id', userData.id)
      }
    }

    // Update job status
    const updateData: any = { status: newStatus }
    
    // If starting work, capture payment
    if (newStatus === 'started' && job.payment_intent_id && job.payment_status === 'pending') {
      // TODO: Capture payment intent
      // This will be handled by Stripe webhook or direct capture
      updateData.payment_status = 'captured'
    }

    // If completed, mark payment as completed
    if (newStatus === 'completed') {
      updateData.payment_status = 'completed'
    }

    const { data: updatedJob, error: updateError } = await serviceClient
      .from('jobs')
      .update(updateData)
      .eq('id', jobId)
      .select()
      .single()

    if (updateError) {
      console.error('Error updating job:', updateError)
      return new Response(
        JSON.stringify({ error: 'Failed to update job status', details: updateError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create job event
    await serviceClient
      .from('job_events')
      .insert({
        job_id: jobId,
        actor_user_id: userData.id,
        event: newStatus,
        location: locationPoint,
        meta: {
          previous_status: currentStatus,
        },
      })

    // Send notifications
    const notificationService = new NotificationService(serviceClient)
    
    // Notify customer
    if (job.customer) {
      await notificationService.sendNotification({
        userId: job.customer_id,
        type: 'job_status_update',
        title: 'Job Status Updated',
        body: `Your job status is now: ${newStatus}`,
        data: {
          job_id: jobId,
          status: newStatus,
          previous_status: currentStatus,
        },
        channels: ['push', 'in_app'],
      })
    }

    // Notify pro
    if (job.pro && !isPro) {
      await notificationService.sendNotification({
        userId: job.assigned_pro_id,
        type: 'job_status_update',
        title: 'Job Status Updated',
        body: `Job status updated to: ${newStatus}`,
        data: {
          job_id: jobId,
          status: newStatus,
          previous_status: currentStatus,
        },
        channels: ['push', 'in_app'],
      })
    }

    return new Response(
      JSON.stringify({
        id: updatedJob.id,
        status: updatedJob.status,
        payment_status: updatedJob.payment_status,
        updated_at: updatedJob.updated_at,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

