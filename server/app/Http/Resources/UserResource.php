<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'admin_permissions' => $this->admin_permissions ?? [],
            'can_access_admin_panel' => $this->canAccessAdminPanel(),
            'can_manage_products' => $this->canManageProducts(),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
