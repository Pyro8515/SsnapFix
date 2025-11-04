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

    const { doc_type, doc_subtype, file_name } = await req.json()
    if (!doc_type || !file_name) {
      return new Response(
        JSON.stringify({ error: 'doc_type and file_name are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get app user
    const { data: appUser } = await supabase
      .from('users')
      .select('*')
      .eq('auth_user_id', authUser.id)
      .single()

    if (!appUser || appUser.account_type !== 'professional') {
      return new Response(
        JSON.stringify({ error: 'Only professionals can upload documents' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate unique file path
    const fileId = crypto.randomUUID()
    const fileExtension = file_name.split('.').pop()
    const path = `pro-docs/${appUser.id}/${doc_type}/${doc_subtype || 'default'}/${fileId}.${fileExtension}`

    // Create presigned URL for upload (Supabase Storage)
    // Note: Supabase Storage uses signed URLs differently than S3
    // For uploads, we use createSignedUploadUrl or createSignedUrl
    const { data: signedData, error: signError } = await serviceClient.storage
      .from('pro-docs')
      .createSignedUrl(path, 3600) // 1 hour expiry

    if (signError) {
      // Try alternative: createSignedUploadUrl if available
      // Or use service role to generate upload URL
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create signed URL', 
          details: signError.message,
          path: path // Return path for direct upload if needed
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Return presigned URL and path
    return new Response(
      JSON.stringify({
        url: signedData?.signedUrl || path,
        path: path,
        fields: {} // S3-style fields not needed for Supabase Storage
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
