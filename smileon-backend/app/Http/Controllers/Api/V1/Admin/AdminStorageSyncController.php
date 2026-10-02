<?php namespace App\Http\Controllers\Api\V1\Admin;
use App\Http\Controllers\Controller;
use App\Models\StorageSync;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminStorageSyncController extends Controller {
    public function index(Request $request): JsonResponse {
        $syncs = StorageSync::with('user:id,name,email','strip:id,uuid,clean_url')
            ->when($request->status, fn($q,$s) => $q->where('status',$s))
            ->orderByDesc('created_at')->paginate($request->per_page ?? 20);
        return response()->json(['success'=>true,'data'=>$syncs]);
    }
    public function retry(Request $request, int $id): JsonResponse {
        $sync = StorageSync::findOrFail($id);
        $sync->update(['status'=>'pending','last_error'=>null]);
        // Dispatch job here: SyncToGoogleDriveJob::dispatch($sync)
        return response()->json(['success'=>true,'message'=>'Sinkronisasi dijadwal ulang.']);
    }
    public function retryAll(Request $request): JsonResponse {
        StorageSync::where('status','failed')->update(['status'=>'pending','last_error'=>null]);
        return response()->json(['success'=>true,'message'=>'Semua sinkronisasi gagal dijadwal ulang.']);
    }
}
