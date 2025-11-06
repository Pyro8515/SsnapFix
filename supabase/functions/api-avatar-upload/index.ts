import { createDbClient, createServiceClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'

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
    const supabase = createDbClient(req)
    const serviceClient = createServiceClient()
    
    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser()
    if (authError || !authUser) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { file_name, auto_approve } = await req.json()
    if (!file_name) {
      return new Response(
        JSON.stringify({ error: 'file_name is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get app user
    const { data: appUser } = await supabase
      .from('users')
      .select('*')
      .eq('auth_user_id', authUser.id)
      .single()

    if (!appUser) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const fileId = crypto.randomUUID()
    const fileExtension = file_name.split('.').pop() || 'jpg'
    
    // Upload to temp path first: avatars-temp/{user_id}/{uuid}.{ext}
    const tempPath = `avatars-temp/${appUser.id}/${fileId}.${fileExtension}`
    
    // Create presigned upload URL for temp bucket
    const { data: signedData, error: signError } = await serviceClient.storage
      .from('pro-avatars')
      .createSignedUploadUrl(tempPath, {
        upsert: false
      })

    if (signError) {
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create signed upload URL', 
          details: signError.message
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        url: signedData.signedUrl,
        path: signedData.path || tempPath,
        temp_path: tempPath,
        final_path: `pro-avatars/${appUser.id}/${fileId}.${fileExtension}`, // Path for final move
        token: signedData.token,
        auto_approve: auto_approve || false
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

