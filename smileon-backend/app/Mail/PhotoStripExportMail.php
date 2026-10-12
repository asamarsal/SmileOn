<?php

namespace App\Mail;

use App\Models\PhotoStrip;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Mail\Mailables\Attachment;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Storage;

class PhotoStripExportMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public PhotoStrip $strip
    ) {
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Hasil Foto SmileOn Kamu Sudah Siap! 📸',
        );
    }

    public function content(): Content
    {
        return new Content(
            htmlString: $this->buildHtml(),
        );
    }

    public function attachments(): array
    {
        $attachments = [];
        $localPath = storage_path("app/public/strips/{$this->strip->uuid}/photostrip_hd.png");

        if (file_exists($localPath)) {
            $attachments[] = Attachment::fromPath($localPath)
                ->as("SmileOn_Photostrip_{$this->strip->uuid}.png")
                ->withMime('image/png');
        }

        return $attachments;
    }

    private function buildHtml(): string
    {
        $cleanUrl = $this->strip->clean_url ?? url("/api/v1/strips/{$this->strip->uuid}/download");
        $shareUrl = $this->strip->share_token
            ? url("/api/v1/strips/share/{$this->strip->share_token}")
            : $cleanUrl;

        return <<<HTML
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #FFF9F9; padding: 24px; color: #333;">
  <div style="max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 32px; border: 1px solid #FFE0E6; box-shadow: 0 4px 12px rgba(255,107,138,0.08);">
    <div style="text-align: center; margin-bottom: 24px;">
      <h1 style="color: #FF5376; margin: 0; font-size: 26px; font-weight: 800;">SmileOn Photobox</h1>
      <p style="color: #888; font-size: 14px; margin-top: 4px;">Kenangan Manis, Tersimpan Selamanya</p>
    </div>

    <p style="font-size: 16px; line-height: 1.5;">Halo!</p>
    <p style="font-size: 15px; line-height: 1.6; color: #555;">
      Terima kasih telah berfoto bersama <strong>SmileOn</strong>! Photostrip resolusi tinggi kamu sudah siap diunduh.
    </p>

    <div style="text-align: center; margin: 30px 0;">
      <a href="{$cleanUrl}" style="background: linear-gradient(135deg, #FF5376, #FF7B90); color: #ffffff; text-decoration: none; padding: 14px 28px; border-radius: 50px; font-weight: bold; font-size: 15px; display: inline-block; box-shadow: 0 4px 14px rgba(255,83,118,0.4);">
        📥 Unduh Photostrip HD
      </a>
    </div>

    <div style="background-color: #FFF5F7; border-radius: 12px; padding: 16px; margin: 20px 0; text-align: center;">
      <p style="margin: 0; font-size: 13px; color: #777;">Tautan Berbagi Publik:</p>
      <a href="{$shareUrl}" style="color: #FF5376; font-size: 14px; word-break: break-all; font-weight: 600;">{$shareUrl}</a>
    </div>

    <p style="font-size: 13px; color: #999; text-align: center; margin-top: 32px;">
      Foto ini juga telah kami lampirkan pada email ini.<br>
      © 2026 SmileOn Photobox Ecosystem. All rights reserved.
    </p>
  </div>
</body>
</html>
HTML;
    }
}
