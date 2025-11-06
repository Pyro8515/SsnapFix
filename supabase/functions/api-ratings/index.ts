import { createDbClient, createServiceClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
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
    const jobIdMatch = url.pathname.match(/\/api-ratings\/([^/]+)/)
    const jobId = jobIdMatch ? jobIdMatch[1] : null

    if (req.method === 'POST') {
      // Create/update rating
      if (!jobId) {
        return new Response(
          JSON.stringify({ error: 'Missing job_id in URL' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      const body = await req.json()
      const { rating, comment } = body

      // Validate rating
      if (!rating || rating < 1 || rating > 5) {
        return new Response(
          JSON.stringify({ error: 'Rating must be between 1 and 5' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Get job
      const { data: job, error: jobError } = await serviceClient
        .from('jobs')
        .select('customer_id, assigned_pro_id, status')
        .eq('id', jobId)
        .single()

      if (jobError || !job) {
        return new Response(
          JSON.stringify({ error: 'Job not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Verify user is the customer
      if (job.customer_id !== userData.id) {
        return new Response(
          JSON.stringify({ error: 'Only the customer can rate this job' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Verify job is completed
      if (job.status !== 'completed') {
        return new Response(
          JSON.stringify({ error: 'Job must be completed before rating' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Verify pro is assigned
      if (!job.assigned_pro_id) {
        return new Response(
          JSON.stringify({ error: 'Job has no assigned professional' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Upsert rating
      const { data: ratingData, error: ratingError } = await serviceClient
        .from('ratings')
        .upsert({
          job_id: jobId,
          customer_id: userData.id,
          pro_user_id: job.assigned_pro_id,
          rating: rating,
          comment: comment || null,
        }, {
          onConflict: 'job_id,customer_id',
        })
        .select()
        .single()

      if (ratingError) {
        console.error('Error creating rating:', ratingError)
        return new Response(
          JSON.stringify({ error: 'Failed to create rating', details: ratingError.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({
          id: ratingData.id,
          job_id: ratingData.job_id,
          pro_user_id: ratingData.pro_user_id,
          rating: ratingData.rating,
          comment: ratingData.comment,
          created_at: ratingData.created_at,
          updated_at: ratingData.updated_at,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } else if (req.method === 'GET') {
      // Get rating(s)
      if (jobId) {
        // Get specific rating for job
        const { data: rating, error: ratingError } = await serviceClient
          .from('ratings')
          .select('*')
          .eq('job_id', jobId)
          .eq('customer_id', userData.id)
          .single()

        if (ratingError && ratingError.code !== 'PGRST116') {
          return new Response(
            JSON.stringify({ error: 'Failed to fetch rating', details: ratingError.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }

        return new Response(
          JSON.stringify(rating || null),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      } else {
        // Get all ratings for user
        const { data: ratings, error: ratingsError } = await serviceClient
          .from('ratings')
          .select('*')
          .eq('customer_id', userData.id)
          .order('created_at', { ascending: false })

        if (ratingsError) {
          return new Response(
            JSON.stringify({ error: 'Failed to fetch ratings', details: ratingsError.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }

        return new Response(
          JSON.stringify(ratings || []),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    } else {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

