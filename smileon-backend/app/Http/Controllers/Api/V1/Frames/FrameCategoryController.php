<?php namespace App\Http\Controllers\Api\V1\Frames;
use App\Http\Controllers\Controller;
use App\Models\FrameCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
class FrameCategoryController extends Controller {
    public function index(): JsonResponse {
        return response()->json(['success'=>true,'data'=>FrameCategory::where('is_active',true)->orderBy('sort_order')->get()]);
    }
    public function adminIndex(): JsonResponse {
        return response()->json(['success'=>true,'data'=>FrameCategory::orderBy('sort_order')->get()]);
    }
    public function store(Request $request): JsonResponse {
        $request->validate(['name'=>'required','slug'=>'required|unique:frame_categories']);
        return response()->json(['success'=>true,'data'=>FrameCategory::create($request->all())],201);
    }
    public function update(Request $request, int $id): JsonResponse {
        $cat = FrameCategory::findOrFail($id);
        $cat->update($request->all());
        return response()->json(['success'=>true,'data'=>$cat]);
    }
    public function destroy(int $id): JsonResponse {
        FrameCategory::findOrFail($id)->delete();
        return response()->json(['success'=>true,'message'=>'Kategori dihapus.']);
    }
}
