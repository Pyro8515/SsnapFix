// Shared types for API responses

export interface UserResponse {
  id: string
  account_type: 'customer' | 'professional'
  active_role: string
  can_switch_roles: boolean
  verification_status: 'pending' | 'approved' | 'rejected'
  avatar_url?: string
  professional_profile?: {
    services: string[]
    identity_status?: string
    payouts_enabled: boolean
    payouts_status?: string
  }
  documents?: DocumentStatus[]
  trade_compliance?: TradeCompliance[]
}

export interface DocumentStatus {
  doc_type: string
  doc_subtype?: string
  status: 'pending' | 'approved' | 'rejected' | 'expired' | 'manual_review'
  expires_at?: string
  reason?: string
}

export interface TradeCompliance {
  trade: string
  compliant: boolean
  reason?: string
}

export interface ErrorResponse {
  error: string
  reasons?: string[]
}

export interface PresignResponse {
  url: string
  fields: Record<string, string>
}

export interface RoleSwitchResponse {
  active_role: string
}
