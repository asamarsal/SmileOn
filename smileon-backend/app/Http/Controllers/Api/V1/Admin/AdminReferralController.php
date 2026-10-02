<?php namespace App\Http\Controllers\Api\V1\Admin;
use App\Http\Controllers\Controller;
use App\Models\Referral;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
class AdminReferralController extends Controller {
    public function index(Request $request): JsonResponse {
        $referrals = Referral::with(['referrer:id,name,email','referred:id,name,email'])
            ->when($request->status, fn($q,$s) => $q->where('status',$s))
            ->orderByDesc('created_at')->paginate($request->per_page ?? 20);
        return response()->json(['success'=>true,'data'=>$referrals]);
    }
}
