<?php

namespace App\Services\Storage;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GoogleDriveService
{
    protected ?string $clientId;
    protected ?string $clientSecret;
    protected ?string $refreshToken;
    protected ?string $folderId;
    protected ?string $serviceAccountJson;
    protected ?string $accessToken = null;

    public function __construct()
    {
        $this->clientId           = config('filesystems.google.client_id', env('GOOGLE_DRIVE_CLIENT_ID'));
        $this->clientSecret       = config('filesystems.google.client_secret', env('GOOGLE_DRIVE_CLIENT_SECRET'));
        $this->refreshToken       = config('filesystems.google.refresh_token', env('GOOGLE_DRIVE_REFRESH_TOKEN'));
        $this->folderId           = config('filesystems.google.folder_id', env('GOOGLE_DRIVE_FOLDER_ID'));
        $this->serviceAccountJson = config('filesystems.google.service_account_json', env('GOOGLE_DRIVE_SERVICE_ACCOUNT_JSON'));
    }

    /**
     * Mengecek apakah kredensial Google Drive telah terisi di .env
     */
    public function isConfigured(): bool
    {
        if (!config('filesystems.google.enabled', env('GOOGLE_DRIVE_ENABLED', true))) {
            return false;
        }

        $hasOAuth = !empty($this->clientId) && !empty($this->clientSecret) && !empty($this->refreshToken);
        $hasServiceAccount = !empty($this->serviceAccountJson) && file_exists(base_path($this->serviceAccountJson));

        return $hasOAuth || $hasServiceAccount;
    }

    /**
     * Mendapatkan OAuth Access Token menggunakan Refresh Token
     */
    public function getAccessToken(): ?string
    {
        if ($this->accessToken) {
            return $this->accessToken;
        }

        if (empty($this->clientId) || empty($this->clientSecret) || empty($this->refreshToken)) {
            Log::warning('GoogleDriveService: Kredensial OAuth Google Drive belum lengkap di .env.');
            return null;
        }

        try {
            $response = Http::asForm()->timeout(15)->post('https://oauth2.googleapis.com/token', [
                'client_id'     => $this->clientId,
                'client_secret' => $this->clientSecret,
                'refresh_token' => $this->refreshToken,
                'grant_type'    => 'refresh_token',
            ]);

            if ($response->successful()) {
                $this->accessToken = $response->json('access_token');
                return $this->accessToken;
            }

            Log::error('GoogleDriveService: Gagal me-refresh token Google Drive.', [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);
            return null;
        } catch (\Throwable $e) {
            Log::error('GoogleDriveService Exception saat request token: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Upload file biner atau string path ke Google Drive Admin
     *
     * @param string $fileContentOrPath Binary content atau absolute path
     * @param string $fileName Nama file di Google Drive
     * @param string|null $targetFolderId ID folder Drive spesifik (jika null, pakai default)
     * @param string $mimeType
     * @return array|null Info file yang berhasil diupload ['file_id', 'web_view_link', 'web_content_link']
     */
    public function uploadFile(
        string $fileContentOrPath,
        string $fileName,
        ?string $targetFolderId = null,
        string $mimeType = 'image/png'
    ): ?array {
        $token = $this->getAccessToken();
        if (!$token) {
            Log::warning("GoogleDriveService: Batal upload '{$fileName}' karena access token tidak tersedia.");
            return null;
        }

        $folder = $targetFolderId ?? $this->folderId;

        // Ambil konten biner
        $binaryContent = file_exists($fileContentOrPath)
            ? file_get_contents($fileContentOrPath)
            : $fileContentOrPath;

        $metadata = [
            'name'     => $fileName,
            'mimeType' => $mimeType,
        ];
        if (!empty($folder)) {
            $metadata['parents'] = [$folder];
        }

        try {
            $boundary = '-------314159265358979323846';
            $delimiter = "\r\n--" . $boundary . "\r\n";
            $closeDelimiter = "\r\n--" . $boundary . "--";

            $multipartBody = $delimiter
                . "Content-Type: application/json; charset=UTF-8\r\n\r\n"
                . json_encode($metadata)
                . $delimiter
                . "Content-Type: {$mimeType}\r\n\r\n"
                . $binaryContent
                . $closeDelimiter;

            $response = Http::withToken($token)
                ->withHeaders([
                    'Content-Type' => 'multipart/related; boundary=' . $boundary,
                ])
                ->timeout(60)
                ->send('POST', 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink,webContentLink', [
                    'body' => $multipartBody,
                ]);

            if ($response->successful()) {
                $data = $response->json();
                Log::info("GoogleDriveService: File '{$fileName}' berhasil disimpan ke Google Drive Admin (ID: {$data['id']}).");

                return [
                    'file_id'          => $data['id'] ?? null,
                    'name'             => $data['name'] ?? $fileName,
                    'web_view_link'    => $data['webViewLink'] ?? "https://drive.google.com/file/d/{$data['id']}/view",
                    'web_content_link' => $data['webContentLink'] ?? null,
                ];
            }

            Log::error('GoogleDriveService: Gagal mengupload file ke Google Drive.', [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);
            return null;
        } catch (\Throwable $e) {
            Log::error("GoogleDriveService Exception saat upload '{$fileName}': " . $e->getMessage());
            return null;
        }
    }

    /**
     * Membuat folder baru di Google Drive Admin (misal folder event atau sesi)
     */
    public function createFolder(string $folderName, ?string $parentFolderId = null): ?array
    {
        $token = $this->getAccessToken();
        if (!$token) {
            return null;
        }

        $parent = $parentFolderId ?? $this->folderId;
        $metadata = [
            'name'     => $folderName,
            'mimeType' => 'application/vnd.google-apps.folder',
        ];
        if (!empty($parent)) {
            $metadata['parents'] = [$parent];
        }

        try {
            $response = Http::withToken($token)
                ->timeout(30)
                ->post('https://www.googleapis.com/drive/v3/files?fields=id,name,webViewLink', $metadata);

            if ($response->successful()) {
                $data = $response->json();
                Log::info("GoogleDriveService: Folder '{$folderName}' berhasil dibuat di Google Drive Admin (ID: {$data['id']}).");
                return [
                    'id'            => $data['id'],
                    'name'          => $data['name'],
                    'web_view_link' => $data['webViewLink'] ?? "https://drive.google.com/drive/folders/{$data['id']}",
                ];
            }
            return null;
        } catch (\Throwable $e) {
            Log::error("GoogleDriveService Exception saat createFolder '{$folderName}': " . $e->getMessage());
            return null;
        }
    }

    /**
     * Upload banyak file (bulk) sekaligus ke folder Google Drive
     */
    public function uploadBulkFiles(array $files, ?string $targetFolderId = null): array
    {
        $results = [];
        foreach ($files as $file) {
            $res = $this->uploadFile(
                $file['content'],
                $file['name'],
                $targetFolderId,
                $file['mime'] ?? 'image/jpeg'
            );
            if ($res) {
                $results[] = $res;
            }
        }
        return $results;
    }
}
