"use client";

import React from "react";
import Link from "next/link";
import Image from "next/image";
import { motion } from "framer-motion";
import { Camera, Home, ArrowLeft, Sparkles, RefreshCw, Compass } from "lucide-react";

export default function NotFoundView() {
  return (
    <main className="relative min-h-screen bg-[#06020B] text-white flex flex-col justify-between items-center px-4 py-8 overflow-hidden selection:bg-[#FF3366] selection:text-white">
      {/* ── Ambient Background Glows ── */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[520px] h-[520px] bg-gradient-to-tr from-[#FF3366]/20 via-[#8C40F0]/20 to-transparent rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute -bottom-24 -left-24 w-96 h-96 bg-[#8C40F0]/15 rounded-full blur-[100px] pointer-events-none" />
      <div className="absolute -top-24 -right-24 w-96 h-96 bg-[#FF3366]/15 rounded-full blur-[100px] pointer-events-none" />

      {/* Grid pattern overlay */}
      <div 
        className="absolute inset-0 opacity-[0.04] pointer-events-none" 
        style={{
          backgroundImage: `radial-gradient(circle at 1px 1px, #ffffff 1px, transparent 0)`,
          backgroundSize: '36px 36px'
        }}
      />

      {/* ── Top Header / Logo Bar ── */}
      <header className="relative z-10 w-full max-w-5xl flex items-center justify-between py-2">
        <Link href="/" className="flex items-center gap-2.5 group">
          <div className="relative w-9 h-9 rounded-xl overflow-hidden p-1 bg-white/5 border border-white/10 group-hover:border-[#FF3366]/50 transition-colors">
            <Image
              src="/smileon-ico.svg"
              alt="SmileOn Logo"
              width={36}
              height={36}
              className="w-full h-full object-contain"
            />
          </div>
          <span className="text-xl font-bold tracking-tight text-white group-hover:text-[#FF3366] transition-colors">
            Smile<span className="text-[#FF3366]">On</span>
          </span>
        </Link>

        <Link
          href="/"
          className="flex items-center gap-2 text-xs md:text-sm font-medium text-gray-400 hover:text-white transition-colors bg-white/5 hover:bg-white/10 border border-white/10 px-3.5 py-1.5 rounded-full backdrop-blur-md"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Kembali</span>
        </Link>
      </header>

      {/* ── Center Content: The Missing Polaroid ── */}
      <div className="relative z-10 max-w-2xl w-full flex flex-col items-center text-center my-auto py-10">
        {/* Floating Polaroid Graphic */}
        <motion.div
          initial={{ opacity: 0, y: 30, rotate: -6, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, rotate: -3, scale: 1 }}
          transition={{ duration: 0.6, ease: "easeOut" }}
          whileHover={{ rotate: 0, scale: 1.03 }}
          className="relative mb-8 cursor-pointer select-none group"
        >
          {/* Polaroid Outer Frame */}
          <div className="w-56 md:w-64 bg-[#FAFAFA] rounded-xl p-3 pb-8 shadow-[0_20px_50px_rgba(0,0,0,0.8),0_0_40px_rgba(255,51,102,0.25)] border border-white/30 transform transition-transform duration-300">
            {/* Masking tape on top */}
            <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 w-20 h-6 bg-[#E8E0D2]/80 backdrop-blur-sm border-t border-b border-black/10 rotate-1 shadow-sm" />

            {/* Photo Viewport Area */}
            <div className="relative w-full aspect-[4/5] bg-gradient-to-b from-[#1C1226] to-[#0A0510] rounded-lg overflow-hidden flex flex-col items-center justify-center p-4 border border-black/10">
              {/* Scanline / Camera Lens Effect */}
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,transparent_30%,rgba(0,0,0,0.6)_100%)] pointer-events-none" />
              
              {/* Camera Shutter Icon with Glitch Glow */}
              <motion.div 
                animate={{ scale: [1, 1.08, 1], opacity: [0.8, 1, 0.8] }}
                transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
                className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-[#FF3366]/20 to-[#8C40F0]/20 border border-[#FF3366]/40 flex items-center justify-center mb-3 text-[#FF3366] shadow-[0_0_20px_rgba(255,51,102,0.3)]"
              >
                <Camera className="w-8 h-8" />
              </motion.div>

              <div className="text-4xl md:text-5xl font-black tracking-tight text-white/90">
                4<span className="text-[#FF3366]">0</span>4
              </div>
              <p className="text-[11px] uppercase tracking-widest font-semibold text-gray-400 mt-1">
                Frame Not Captured
              </p>

              {/* Status indicator badge */}
              <div className="mt-3 px-2 py-0.5 rounded-full bg-red-500/10 border border-red-500/20 text-red-400 text-[10px] font-mono flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-red-400 animate-pulse" />
                OUT OF FOCUS
              </div>
            </div>

            {/* Handwritten note at bottom of polaroid */}
            <div className="mt-3 text-center">
              <span className="text-[#2B1B2A] font-medium text-lg font-[var(--font-caveat),cursive] tracking-wide">
                Oops, fotonya belum ada! ✨
              </span>
            </div>
          </div>

          {/* Decorative Sparkles */}
          <Sparkles className="absolute -top-2 -right-4 w-7 h-7 text-[#FF3366] animate-pulse pointer-events-none" />
          <Sparkles className="absolute -bottom-2 -left-4 w-5 h-5 text-[#8C40F0] animate-bounce pointer-events-none" />
        </motion.div>

        {/* Text Details */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.15 }}
          className="space-y-3"
        >
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/5 border border-white/10 text-xs text-gray-300">
            <span className="w-2 h-2 rounded-full bg-[#FF3366]" />
            Halaman Tidak Ditemukan
          </div>

          <h1 className="text-3xl md:text-5xl font-extrabold tracking-tight">
            Sepertinya Momen Ini{" "}
            <span className="bg-gradient-to-r from-[#FF3366] via-[#FF6699] to-[#8C40F0] bg-clip-text text-transparent">
              Belum Dijepret
            </span>
          </h1>

          <p className="text-sm md:text-base text-gray-400 max-w-md mx-auto leading-relaxed">
            Halaman atau tautan yang kamu tuju tidak tersedia, telah dipindahkan, atau belum didefinisikan di sistem SmileOn.
          </p>
        </motion.div>

        {/* Action CTA Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
          className="flex flex-wrap items-center justify-center gap-3.5 mt-8 w-full max-w-md"
        >
          {/* Primary Action: Back to Home */}
          <Link
            href="/"
            className="flex-1 min-w-[170px] inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-2xl bg-gradient-to-r from-[#FF3366] to-[#FF6699] text-white font-semibold text-sm shadow-[0_0_25px_rgba(255,51,102,0.45)] hover:shadow-[0_0_35px_rgba(255,51,102,0.7)] hover:scale-[1.02] active:scale-[0.98] transition-all"
          >
            <Home className="w-4 h-4" />
            <span>Kembali ke Beranda</span>
          </Link>

          {/* Secondary Action: Explore Features */}
          <Link
            href="/#features"
            className="flex-1 min-w-[170px] inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 hover:border-white/20 text-white font-semibold text-sm backdrop-blur-md hover:scale-[1.02] active:scale-[0.98] transition-all"
          >
            <Compass className="w-4 h-4 text-[#FF6699]" />
            <span>Eksplor Fitur</span>
          </Link>
        </motion.div>

        {/* Helpful Shortcut Pills */}
        <div className="flex flex-wrap items-center justify-center gap-2 mt-8 text-xs text-gray-500">
          <span>Mungkin kamu mencari:</span>
          <Link href="/#download" className="text-gray-300 hover:text-[#FF3366] underline underline-offset-4 transition-colors">
            Download Aplikasi
          </Link>
          <span>•</span>
          <Link href="/#gallery" className="text-gray-300 hover:text-[#FF3366] underline underline-offset-4 transition-colors">
            Galeri Frame
          </Link>
          <span>•</span>
          <Link href="/#faq" className="text-gray-300 hover:text-[#FF3366] underline underline-offset-4 transition-colors">
            Bantuan FAQ
          </Link>
        </div>
      </div>

      {/* ── Bottom Footer ── */}
      <footer className="relative z-10 w-full max-w-5xl flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-gray-500 border-t border-white/5 pt-4">
        <p>© {new Date().getFullYear()} SmileOn. Make a moment. Make it SmileOn.</p>
        <div className="flex items-center gap-4 text-gray-400">
          <Link href="/" className="hover:text-white transition-colors">Beranda</Link>
          <span>•</span>
          <Link href="/#event" className="hover:text-white transition-colors">Sewa Photobooth</Link>
          <span>•</span>
          <button 
            onClick={() => window.location.reload()} 
            className="inline-flex items-center gap-1 hover:text-white transition-colors"
          >
            <RefreshCw className="w-3 h-3" />
            <span>Muat Ulang</span>
          </button>
        </div>
      </footer>
    </main>
  );
}
