package types

import (
	"fmt"
	"strings"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// --- Status enum ---

type MerchantStatus int32

const (
	MerchantStatusActive   MerchantStatus = 0
	MerchantStatusInactive MerchantStatus = 1
	MerchantStatusClosed   MerchantStatus = 2
)

func MerchantStatusFromString(s string) MerchantStatus {
	switch strings.ToLower(s) {
	case "active":
		return MerchantStatusActive
	case "inactive":
		return MerchantStatusInactive
	case "closed":
		return MerchantStatusClosed
	default:
		return MerchantStatusInactive
	}
}

func (s MerchantStatus) String() string {
	switch s {
	case MerchantStatusActive:
		return "active"
	case MerchantStatusInactive:
		return "inactive"
	case MerchantStatusClosed:
		return "closed"
	default:
		return "unknown"
	}
}

// --- VerificationStatus enum ---

type VerificationStatus int32

const (
	VerificationUnverified VerificationStatus = 0
	VerificationVerified   VerificationStatus = 1
	VerificationRejected   VerificationStatus = 2
)

func VerificationStatusFromString(s string) VerificationStatus {
	switch strings.ToLower(s) {
	case "unverified":
		return VerificationUnverified
	case "verified":
		return VerificationVerified
	case "rejected":
		return VerificationRejected
	default:
		return VerificationUnverified
	}
}

func (s VerificationStatus) String() string {
	switch s {
	case VerificationUnverified:
		return "unverified"
	case VerificationVerified:
		return "verified"
	case VerificationRejected:
		return "rejected"
	default:
		return "unknown"
	}
}

// --- RebateTier enum ---

type RebateTier int32

const (
	RebateTierNone     RebateTier = 0
	RebateTierBronze   RebateTier = 1
	RebateTierSilver   RebateTier = 2
	RebateTierGold     RebateTier = 3
	RebateTierPlatinum RebateTier = 4
)

func RebateTierFromString(s string) RebateTier {
	switch strings.ToLower(s) {
	case "none":
		return RebateTierNone
	case "bronze":
		return RebateTierBronze
	case "silver":
		return RebateTierSilver
	case "gold":
		return RebateTierGold
	case "platinum":
		return RebateTierPlatinum
	default:
		return RebateTierNone
	}
}

func (r RebateTier) String() string {
	switch r {
	case RebateTierNone:
		return "none"
	case RebateTierBronze:
		return "bronze"
	case RebateTierSilver:
		return "silver"
	case RebateTierGold:
		return "gold"
	case RebateTierPlatinum:
		return "platinum"
	default:
		return "unknown"
	}
}

// --- Merchant struct ---

type Merchant struct {
	Owner              string `json:"owner" yaml:"owner"`
	Name               string `json:"name" yaml:"name"`
	Description        string `json:"description" yaml:"description"`
	Website            string `json:"website" yaml:"website"`
	Status             int32  `json:"status" yaml:"status"`
	VerificationStatus int32  `json:"verification_status" yaml:"verification_status"`
	RebateTier         int32  `json:"rebate_tier" yaml:"rebate_tier"`
	CreatedAt          int64  `json:"created_at" yaml:"created_at"`
	UpdatedAt          int64  `json:"updated_at" yaml:"updated_at"`
}

func NewMerchant(owner sdk.AccAddress, name, description, website string, createdAt, updatedAt int64) Merchant {
	return Merchant{
		Owner:              owner.String(),
		Name:               strings.TrimSpace(name),
		Description:        strings.TrimSpace(description),
		Website:            strings.TrimSpace(website),
		Status:             int32(MerchantStatusActive),
		VerificationStatus: int32(VerificationUnverified),
		RebateTier:         int32(RebateTierNone),
		CreatedAt:          createdAt,
		UpdatedAt:          updatedAt,
	}
}

func (m *Merchant) ProtoMessage()  {}
func (m *Merchant) Reset()         { *m = Merchant{} }
func (m *Merchant) String() string { return fmt.Sprintf("Merchant{%s, %s}", m.Owner, m.Name) }

func (m Merchant) Validate() error {
	if _, err := sdk.AccAddressFromBech32(m.Owner); err != nil {
		return fmt.Errorf("invalid owner address: %w", ErrInvalidOwner)
	}
	if len(strings.TrimSpace(m.Name)) == 0 {
		return fmt.Errorf("merchant name is required")
	}
	return nil
}

func (m Merchant) ValidateWithParams(params Params) error {
	if err := m.Validate(); err != nil {
		return err
	}
	nameLen := uint32(len(strings.TrimSpace(m.Name)))
	if nameLen < params.MinNameLength {
		return fmt.Errorf("name length %d below minimum %d: %w", nameLen, params.MinNameLength, ErrNameTooShort)
	}
	if nameLen > params.MaxNameLength {
		return fmt.Errorf("name length %d above maximum %d: %w", nameLen, params.MaxNameLength, ErrNameTooLong)
	}
	descLen := uint32(len(m.Description))
	if descLen > params.MaxDescriptionLength {
		return fmt.Errorf("description length %d above maximum %d: %w", descLen, params.MaxDescriptionLength, ErrDescriptionTooLong)
	}
	return nil
}

func (m Merchant) IsActive() bool { return m.Status == int32(MerchantStatusActive) }
func (m Merchant) IsClosed() bool { return m.Status == int32(MerchantStatusClosed) }

func (m Merchant) GetOwnerAddress() (sdk.AccAddress, error) {
	return sdk.AccAddressFromBech32(m.Owner)
}
