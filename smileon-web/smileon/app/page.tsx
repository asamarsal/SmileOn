"use client";

import React, { useEffect, useState, useRef } from "react";
import { motion, useScroll, useTransform, AnimatePresence } from "framer-motion";
import { Heart, Camera, Calendar, Image as ImageIcon, Link as LinkIcon, Check, ArrowRight, Mail, ChevronLeft, ChevronRight, Star, Sparkles } from "lucide-react";

/* ───────── Icon helpers ───────── */
const InstagramIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
    <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" />
    <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
  </svg>
);

const GooglePlayIcon = () => (
  <svg className="w-6 h-6 shrink-0" viewBox="0 0 24 24">
    <path fill="#EA4335" d="M3.609 2.233L13.5 12 3.609 21.767A1.5 1.5 0 013 20.5v-17c0-.492.237-.927.609-1.267z" />
    <path fill="#FBBC04" d="M16.5 9l-2.991 3L3.61 2.233C4.13 1.836 4.81 1.8 5.392 2.118L16.5 9z" />
    <path fill="#34A853" d="M16.5 15l-11.108 6.882c-.582.318-1.262.282-1.782-.115L13.509 12 16.5 15z" />
    <path fill="#4285F4" d="M21.5 12c0 .796-.436 1.538-1.148 1.93L17.5 15.5 14.5 12l3-2.5 2.852 1.57A2.155 2.155 0 0121.5 12z" />
  </svg>
);

const AppleIcon = () => (
  <svg className="w-6 h-6 shrink-0 fill-white" viewBox="0 0 24 24">
    <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.04 2.26-.8 3.59-.72 1.58.11 2.82.85 3.55 2.11-2.91 1.62-2.45 5.5.47 6.74-.69 1.63-1.6 3.19-2.69 4.04zm-4.71-13.4c.16-2.53 2.16-4.5 4.54-4.88-.41 2.65-2.58 4.47-4.54 4.88z" />
  </svg>
);

const MonadIcon = () => (
  <svg className="w-4 h-4" viewBox="0 0 20 20" fill="none">
    <rect width="20" height="20" rx="4" fill="#6B3FE7" />
    <path d="M5 14V8l5 4 5-4v6" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);

/* ───────── App Store Buttons ───────── */
const AppStoreButton = ({ type }: { type: "apple" | "google" }) => (
  <button className="flex items-center gap-3 bg-[#1c1c1e] border border-white/20 hover:border-white/40 text-white rounded-2xl px-5 py-3 transition-all hover:bg-white/10 group">
    {type === "google" ? <GooglePlayIcon /> : <AppleIcon />}
    <div className="text-left">
      <div className="text-[10px] text-gray-400 leading-none mb-0.5">{type === "google" ? "Get it on" : "Download on the"}</div>
      <div className="text-base font-bold leading-tight">{type === "google" ? "Google Play" : "App Store"}</div>
    </div>
    <ArrowRight className="w-4 h-4 ml-1 text-gray-500 group-hover:text-white transition-colors" />
  </button>
);

/* ───────── Floating Sparkles ───────── */
const FloatingStars = () => (
  <div className="absolute inset-0 pointer-events-none overflow-hidden">
    {[
      { top: "12%", left: "8%", size: 14, delay: 0 },
      { top: "5%", left: "55%", size: 10, delay: 0.5 },
      { top: "30%", right: "5%", size: 18, delay: 1 },
      { top: "70%", left: "3%", size: 12, delay: 1.5 },
      { bottom: "20%", right: "8%", size: 10, delay: 2 },
      { top: "55%", left: "48%", size: 8, delay: 0.8 },
      { top: "80%", left: "70%", size: 16, delay: 1.2 },
    ].map((s, i) => (
      <motion.div
        key={i}
        style={{ position: "absolute", top: s.top, left: s.left, right: (s as any).right, bottom: (s as any).bottom }}
        animate={{ opacity: [0.3, 1, 0.3], scale: [0.8, 1.2, 0.8] }}
        transition={{ duration: 2.5 + i * 0.3, repeat: Infinity, delay: s.delay, ease: "easeInOut" }}
      >
        <Star style={{ width: s.size, height: s.size }} className="fill-white/60 text-white/60" />
      </motion.div>
    ))}
  </div>
);

/* ───────── Main Page ───────── */
export default function Home() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  if (!mounted) return null;

  return (
    <div className="bg-[#0d0010] text-white min-h-screen overflow-x-hidden">

      {/* ── BG gradient blobs ── */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        {/* Left blob */}
        <div className="absolute top-[-10%] left-[-15%] w-[65vw] h-[65vw] rounded-full bg-[#FF3366]/25 blur-[140px]" />
        {/* Centre-right blob */}
        <div className="absolute top-[10%] right-[-10%] w-[55vw] h-[55vw] rounded-full bg-[#CC1144]/20 blur-[120px]" />
        {/* Bottom dark purple */}
        <div className="absolute bottom-[-10%] left-[30%] w-[50vw] h-[50vw] rounded-full bg-[#6B3FE7]/15 blur-[100px]" />
        {/* Cherry blossom petals (pink bokeh) */}
        {[
          { top: "15%", left: "2%", size: 180, opacity: 0.12 },
          { top: "60%", right: "0%", size: 220, opacity: 0.08 },
          { bottom: "5%", left: "10%", size: 160, opacity: 0.1 },
        ].map((b, i) => (
          <div
            key={i}
            style={{
              position: "absolute",
              top: b.top,
              left: (b as any).left,
              right: (b as any).right,
              bottom: (b as any).bottom,
              width: b.size,
              height: b.size,
              borderRadius: "50%",
              background: `radial-gradient(circle, rgba(255,100,160,${b.opacity}) 0%, transparent 70%)`,
            }}
          />
        ))}
      </div>

      {/* ══════════════════════════════════════
          NAVBAR
      ══════════════════════════════════════ */}
      <header className="fixed top-0 w-full z-50 backdrop-blur-xl bg-black/30 border-b border-white/5">
        <div className="max-w-[1400px] mx-auto px-8 h-[68px] flex items-center justify-between">
          {/* Logo */}
          <div className="flex items-center gap-2">
            <Heart className="w-5 h-5 text-[#FF3366] fill-[#FF3366]" />
            <span className="text-lg font-extrabold tracking-tight">SmileOn</span>
          </div>

          {/* Nav links */}
          <nav className="hidden md:flex items-center gap-8 text-[13px] font-medium text-white/70">
            {["Product","Personal","Events","Frames","About"].map(l => (
              <a key={l} href="#" className="hover:text-white transition-colors">{l}</a>
            ))}
          </nav>

          {/* Right CTA */}
          <div className="flex items-center gap-4">
            <a href="#" className="text-white/50 hover:text-white transition-colors hidden sm:block">
              <InstagramIcon className="w-5 h-5" />
            </a>
            <button className="bg-gradient-to-r from-[#FF3366] to-[#FF6699] text-white text-[13px] font-bold px-5 py-2 rounded-full flex items-center gap-1.5 hover:shadow-[0_0_20px_rgba(255,51,102,0.5)] transition-shadow">
              Download App <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </header>

      {/* ══════════════════════════════════════
          HERO SECTION
      ══════════════════════════════════════ */}
      <section className="relative z-10 pt-[120px] pb-0 min-h-screen overflow-hidden">
        <FloatingStars />

        <div className="max-w-[1400px] mx-auto px-8 grid grid-cols-1 lg:grid-cols-[1fr_1.1fr] gap-8 items-start">

          {/* ── Left copy ── */}
          <div className="relative z-10 pt-10 pb-24">

            {/* Pill badges */}
            <div className="flex flex-wrap gap-2 mb-8">
              <span className="bg-white text-black text-[11px] font-bold tracking-wider px-3.5 py-1.5 rounded-full">ONCHAIN PHOTOBOOTH</span>
              <span className="border border-white/20 text-white/80 text-[11px] font-semibold px-3.5 py-1.5 rounded-full flex items-center gap-1.5 bg-white/5">
                <MonadIcon /> Built on Monad
              </span>
            </div>

            {/* H1 */}
            <h1 className="text-[58px] md:text-[70px] font-extrabold leading-[1.05] tracking-tight mb-6">
              Make a moment.<br />
              Make it{" "}
              <span className="bg-gradient-to-r from-[#FF3366] to-[#FF88AA] bg-clip-text text-transparent">SmileOn.</span>
            </h1>

            <p className="text-[17px] text-white/60 mb-10 max-w-md leading-relaxed">
              Capture, customize, and share your memories —<br />anytime, anywhere.
            </p>

            {/* App buttons */}
            <div className="flex flex-col sm:flex-row gap-3 mb-10">
              <AppStoreButton type="google" />
              <AppStoreButton type="apple" />
            </div>

            {/* Social proof */}
            <div className="flex items-center gap-4">
              <div className="flex -space-x-2.5">
                {[20,21,22,23].map(n => (
                  <img key={n} src={`https://i.pravatar.cc/80?img=${n}`} alt="" className="w-9 h-9 rounded-full border-2 border-[#0d0010] object-cover" />
                ))}
              </div>
              <p className="text-[13px] text-white/50 max-w-[180px] leading-snug">
                For couples, friends, creators, events and more.
              </p>
            </div>

            {/* Handwritten annotation */}
            <div className="absolute -left-2 bottom-4 -rotate-12 opacity-80 hidden lg:block">
              <p className="font-['Caveat',_cursive] text-2xl text-[#FF88AA] leading-tight">
                Photobooth,<br />without<br />the booth.
                <span className="text-[#FF3366]"> ♡</span>
              </p>
              {/* hand-drawn arrow */}
              <svg width="60" height="50" viewBox="0 0 60 50" className="mt-1 text-[#FF88AA] opacity-70">
                <path d="M10,10 Q30,5 50,30" stroke="currentColor" strokeWidth="1.5" fill="none" strokeLinecap="round" />
                <path d="M45,26 L52,32 L44,35" stroke="currentColor" strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
          </div>

          {/* ── Right hero visuals ── */}
          <div className="relative h-[700px] w-full hidden lg:block">

            {/* Ribbon / ring */}
            <motion.div
              className="absolute top-[45%] left-[35%] -translate-x-1/2 -translate-y-1/2 w-[500px] h-[600px] rounded-full border border-[#FF3366]/20 border-dashed pointer-events-none"
              animate={{ rotate: 360 }}
              transition={{ duration: 80, repeat: Infinity, ease: "linear" }}
            />

            {/* Pink glow behind phone */}
            <div className="absolute top-[10%] left-[22%] w-[320px] h-[600px] bg-[#FF3366]/30 blur-[80px] rounded-full pointer-events-none" />

            {/* MAIN PHONE MOCKUP */}
            <motion.div
              initial={{ y: 30, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              className="absolute top-[2%] left-[18%] w-[270px] h-[560px] rounded-[42px] border-4 border-[#2a2a2a] shadow-[0_0_60px_rgba(255,51,102,0.35)] overflow-hidden z-20 bg-black"
              style={{ transform: "perspective(1000px) rotateY(-8deg) rotateX(3deg)" }}
            >
              {/* full-bleed photo */}
              <img
                src="https://images.unsplash.com/photo-1529080765917-3db2ac54491f?auto=format&fit=crop&q=80&w=540"
                alt="couple"
                className="w-full h-full object-cover"
              />
              {/* top UI bar */}
              <div className="absolute top-0 left-0 right-0 px-5 pt-5 flex items-center justify-between">
                <span className="text-white/80 text-[11px] font-semibold bg-black/30 backdrop-blur-sm rounded px-2 py-0.5">2/4</span>
                <span className="text-white font-bold text-[13px] bg-black/30 backdrop-blur-sm rounded px-2 py-0.5">SmileOn</span>
                <div className="w-5 h-5" />
              </div>
              {/* bottom capture bar */}
              <div className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-black/90 to-transparent flex flex-col items-center justify-end pb-5 gap-3">
                <div className="flex items-center gap-4 text-[10px] text-white/60 font-semibold">
                  <span>Template</span>
                  <span>Filter</span>
                  <span className="text-white">Photo</span>
                  <span>Video</span>
                  <span>Background</span>
                </div>
                <div className="w-14 h-14 rounded-full bg-gradient-to-br from-[#FF3366] to-[#FF88AA] shadow-[0_0_20px_#FF3366] border-4 border-white/30 flex items-center justify-center">
                  <div className="w-6 h-6 rounded-full bg-[#FF3366]" />
                </div>
              </div>
            </motion.div>

            {/* PHOTOSTRIP — right, large */}
            <motion.div
              animate={{ y: [-8, 8, -8], rotate: [4, 6, 4] }}
              transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
              className="absolute top-[4%] right-[4%] w-[160px] bg-white rounded-sm shadow-2xl z-30 overflow-hidden"
              style={{ padding: "6px 6px 20px 6px" }}
            >
              {[
                "https://images.unsplash.com/photo-1529080765917-3db2ac54491f?auto=format&fit=crop&q=80&w=320&h=320",
                "https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80&w=320&h=320",
                "https://images.unsplash.com/photo-1506869640319-baa18047b8ea?auto=format&fit=crop&q=80&w=320&h=320",
                "https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80&w=320&h=320",
              ].map((src, i) => (
                <img key={i} src={src} alt="" className="w-full object-cover mb-1" style={{ height: 110 }} />
              ))}
              <div className="text-[10px] font-bold text-center text-[#FF3366] py-1" style={{ fontFamily: "Caveat, cursive", fontSize: 13 }}>SmileOn</div>
            </motion.div>

            {/* PHOTOSTRIP — left floating */}
            <motion.div
              animate={{ y: [10, -10, 10], rotate: [-12, -10, -12] }}
              transition={{ duration: 6, repeat: Infinity, ease: "easeInOut", delay: 1.2 }}
              className="absolute top-[20%] left-[-2%] w-[130px] bg-white rounded-sm shadow-2xl z-10 overflow-hidden"
              style={{ padding: "6px 6px 16px 6px", rotate: "-12deg" }}
            >
              {[
                "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80&w=260&h=260",
                "https://images.unsplash.com/photo-1523824922871-d6f1a15151f1?auto=format&fit=crop&q=80&w=260&h=260",
                "https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&q=80&w=260&h=260",
              ].map((src, i) => (
                <img key={i} src={src} alt="" className="w-full object-cover mb-1" style={{ height: 90 }} />
              ))}
              <div className="text-center py-1" style={{ fontFamily: "Caveat, cursive", fontSize: 12, color: "#FF3366" }}>♡ Love</div>
            </motion.div>

            {/* 3D CRYSTAL HEART */}
            <motion.div
              animate={{ y: [-6, 6, -6], rotate: [0, 5, 0] }}
              transition={{ duration: 4, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
              className="absolute top-[12%] right-[28%] z-30"
            >
              <div className="w-24 h-24 relative">
                <div className="absolute inset-0 rounded-[20px] rotate-45 bg-gradient-to-br from-[#FF88AA]/40 to-[#FF3366]/20 backdrop-blur-sm border border-white/30 shadow-[0_0_30px_rgba(255,51,102,0.4)]" />
                <div className="absolute inset-0 flex items-center justify-center">
                  <Heart className="w-10 h-10 text-[#FF3366] fill-[#FF3366] drop-shadow-[0_0_8px_#FF3366]" />
                </div>
              </div>
            </motion.div>

            {/* "Good Memories Onchain" label */}
            <div className="absolute top-[4%] right-[22%] z-40">
              <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl px-4 py-2 shadow-xl">
                <p style={{ fontFamily: "Caveat, cursive", fontSize: 14, color: "#FFB0C8", lineHeight: 1.4 }}>
                  Good<br/>Memories<br/>Onchain
                </p>
              </div>
            </div>

            {/* "Built on Monad" badge floating */}
            <motion.div
              animate={{ y: [-5, 5, -5] }}
              transition={{ duration: 3.5, repeat: Infinity, ease: "easeInOut", delay: 0.8 }}
              className="absolute bottom-[15%] right-[6%] z-30"
            >
              <div className="bg-[#110B29] border border-[#6B3FE7]/50 rounded-2xl px-4 py-2.5 flex items-center gap-2 shadow-[0_0_20px_rgba(107,63,231,0.3)]">
                <MonadIcon />
                <div>
                  <div className="text-[8px] text-white/50 font-semibold uppercase tracking-wider">Built on</div>
                  <div className="text-sm font-extrabold text-white">Monad</div>
                </div>
              </div>
            </motion.div>

            {/* "Your Memories Live On" annotation */}
            <div className="absolute bottom-[35%] right-[0%] z-20 text-right">
              <p style={{ fontFamily: "Caveat, cursive", fontSize: 18, color: "#FF88AA", lineHeight: 1.4 }}>
                Your<br/>Memories<br/>Live On<br/>
                <span className="text-[#FF3366] text-2xl">♡</span>
              </p>
            </div>

            {/* RIBBON marquee text */}
            <div className="absolute bottom-[10%] left-[0%] right-[-5%] z-30 overflow-hidden">
              <div
                className="whitespace-nowrap py-2 px-8 text-[11px] font-bold tracking-widest text-black"
                style={{
                  background: "linear-gradient(90deg, rgba(255,51,102,0.9) 0%, rgba(255,136,170,0.85) 50%, rgba(255,51,102,0.9) 100%)",
                  transform: "rotate(-3deg) scaleX(1.2)",
                  boxShadow: "0 0 30px rgba(255,51,102,0.5)",
                }}
              >
                REAL MOMENTS &nbsp;✦&nbsp; ONCHAIN MEMORIES &nbsp;✦&nbsp; FOR EVERYONE &nbsp;✦&nbsp; REAL MOMENTS &nbsp;✦&nbsp; ONCHAIN MEMORIES &nbsp;✦&nbsp; FOR EVERYONE
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════
          FEATURE PILLS ROW
      ══════════════════════════════════════ */}
      <section className="relative z-10 border-t border-white/5 bg-black/40 backdrop-blur-md">
        <div className="max-w-[1400px] mx-auto px-8 py-6 grid grid-cols-2 lg:grid-cols-4 gap-6">
          {[
            { Icon: Camera, title: "Personal Mode", desc: "Take photos with your partner, friends, or yourself." },
            { Icon: Calendar, title: "Event Mode", desc: "Create a photobooth for any event." },
            { Icon: ImageIcon, title: "Creator Frames", desc: "Unique frames by creators and communities." },
            { Icon: LinkIcon, title: "Onchain Ownership", desc: "Your memories, powered by Monad." },
          ].map(({ Icon, title, desc }, i) => (
            <div key={i} className="flex items-start gap-3">
              <div className="mt-0.5 w-10 h-10 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center shrink-0">
                <Icon className="w-5 h-5 text-[#FF3366]" />
              </div>
              <div>
                <div className="font-bold text-[14px] mb-0.5">{title}</div>
                <div className="text-[12px] text-white/50 leading-snug">{desc}</div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ══════════════════════════════════════
          WHY SMILEON  ⟷  PERSONAL MODE  (split card row)
      ══════════════════════════════════════ */}
      <section className="relative z-10 py-16 px-8">
        <div className="max-w-[1400px] mx-auto grid lg:grid-cols-2 gap-5">

          {/* ── Card left: Why SmileOn ── */}
          <div className="bg-[#FFF2F6] rounded-3xl p-10 text-black flex flex-col min-h-[440px] overflow-hidden relative">
            <div className="text-[11px] font-extrabold tracking-[0.15em] text-[#FF3366] mb-3 uppercase">Why SmileOn</div>
            <h2 className="text-[34px] font-extrabold leading-tight mb-4">Photobooths<br />shouldn't belong<br />to a machine.</h2>
            <p className="text-gray-600 text-[14px] leading-relaxed mb-8 max-w-xs">
              Traditional photobooths are tied to expensive hardware, locations, and setup. SmileOn turns devices people already have into a photobooth experience.
            </p>
            <button className="bg-[#FF3366] text-white rounded-full px-6 py-2.5 font-bold text-[13px] flex items-center gap-2 w-fit hover:bg-[#e02255] transition-colors mb-auto">
              Learn More <ArrowRight className="w-3.5 h-3.5" />
            </button>

            {/* Comparison widget */}
            <div className="mt-10 flex items-center gap-3">
              {/* Traditional booth column */}
              <div className="flex-1 bg-white rounded-2xl p-4 shadow-sm border border-gray-100 relative overflow-hidden">
                <div className="flex justify-center mb-3">
                  {/* booth illustration placeholder */}
                  <div className="w-16 h-20 bg-gray-300 rounded-lg opacity-60 flex items-center justify-center">
                    <span className="text-[8px] text-gray-500 font-bold text-center leading-tight">BOOTH</span>
                  </div>
                </div>
                <div className="text-[11px] font-bold text-gray-500 text-center mb-2">Traditional Booth</div>
                {["Machine","Location","Setup","Limited time"].map(s => (
                  <div key={s} className="flex items-center gap-1.5 text-[12px] text-gray-500 mb-1">
                    <span className="text-red-400 font-bold">✕</span> {s}
                  </div>
                ))}
              </div>

              {/* Arrow */}
              <div className="shrink-0 w-8 h-8 rounded-full bg-[#FF3366] flex items-center justify-center shadow-lg">
                <ArrowRight className="w-4 h-4 text-white" />
              </div>

              {/* SmileOn column */}
              <div className="flex-1 bg-white rounded-2xl p-4 shadow-sm border border-pink-100 relative overflow-hidden">
                <div className="flex justify-center mb-3">
                  <div className="flex items-center gap-1.5">
                    <Heart className="w-4 h-4 text-[#FF3366] fill-[#FF3366]" />
                    <span className="text-[12px] font-bold text-[#FF3366]">SmileOn</span>
                  </div>
                </div>
                <div className="text-[11px] font-bold text-[#FF3366] text-center mb-2">SmileOn</div>
                {["Phone / Tablet","Anywhere","Instant setup","Any moment"].map(s => (
                  <div key={s} className="flex items-center gap-1.5 text-[12px] text-[#FF3366] mb-1 font-semibold">
                    <Check className="w-3.5 h-3.5" /> {s}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* ── Card right: Personal Mode ── */}
          <div className="bg-[#120A1D] rounded-3xl p-10 text-white flex flex-col min-h-[440px] overflow-hidden relative border border-[#FF3366]/10">
            {/* glow */}
            <div className="absolute top-0 right-0 w-60 h-60 bg-[#FF3366]/10 blur-[80px] rounded-full pointer-events-none" />
            <div className="absolute bottom-0 left-0 w-40 h-40 bg-[#FF3366]/5 blur-[60px] rounded-full pointer-events-none" />

            <div className="relative z-10">
              <div className="text-[11px] font-extrabold tracking-[0.15em] text-white/40 mb-3 uppercase">Personal Mode</div>
              <h2 className="text-[34px] font-extrabold leading-tight mb-4">For the moments<br />you want to keep.</h2>
              <p className="text-white/50 text-[14px] leading-relaxed mb-8 max-w-xs">
                Take photos, choose a frame, customize the look, and turn a few seconds into a memory.
              </p>
              <button className="border-2 border-[#FF3366] text-[#FF3366] rounded-full px-6 py-2.5 font-bold text-[13px] flex items-center gap-2 w-fit hover:bg-[#FF3366] hover:text-white transition-colors">
                Explore Personal Mode <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* phone mockup bottom-right */}
            <div className="absolute -bottom-6 -right-4 w-[240px] h-[340px] bg-black rounded-[32px] border-4 border-[#222] shadow-2xl overflow-hidden z-20" style={{ transform: "perspective(800px) rotateY(-10deg) rotate(-4deg)" }}>
              {/* top bar */}
              <div className="px-4 pt-4 pb-2 text-[9px] text-white/40 flex justify-between items-center">
                <span>Frames</span><span>Filter</span><span>Background</span>
              </div>
              {/* frame selector pills */}
              <div className="flex gap-2 px-3 mb-2 overflow-hidden">
                {["Romantic","Floral","Minimal","Arcade"].map((f, i) => (
                  <div key={f} className={`text-[8px] font-bold px-2 py-0.5 rounded-full whitespace-nowrap ${i === 0 ? 'bg-[#FF3366] text-white' : 'bg-white/10 text-white/50'}`}>{f}</div>
                ))}
              </div>
              {/* photos */}
              <div className="flex gap-1 px-3">
                {[
                  "https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80&w=200",
                  "https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80&w=200",
                ].map((src, i) => (
                  <div key={i} className="flex-1 rounded-lg overflow-hidden bg-[#FFE4E1]" style={{ paddingTop: 4, paddingBottom: 4, paddingLeft: 2, paddingRight: 2 }}>
                    <img src={src} alt="" className="w-full rounded" style={{ height: 80, objectFit: "cover" }} />
                    <img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80&w=200" alt="" className="w-full rounded mt-1" style={{ height: 80, objectFit: "cover" }} />
                    <img src="https://images.unsplash.com/photo-1506869640319-baa18047b8ea?auto=format&fit=crop&q=80&w=200" alt="" className="w-full rounded mt-1" style={{ height: 80, objectFit: "cover" }} />
                  </div>
                ))}
              </div>
            </div>
          </div>

        </div>
      </section>

      {/* ══════════════════════════════════════
          REMAINING SECTIONS (continued scroll)
      ══════════════════════════════════════ */}

      {/* Gesture Capture & Event Mode */}
      <section className="relative z-10 py-4 px-8">
        <div className="max-w-[1400px] mx-auto grid lg:grid-cols-2 gap-5">

          {/* Gesture */}
          <div className="bg-[#FDF2F8] rounded-3xl p-10 text-black min-h-[420px] relative overflow-hidden">
            <div className="text-[11px] font-extrabold tracking-[0.15em] text-[#FF3366] mb-3 uppercase">Gesture Capture</div>
            <h2 className="text-[30px] font-extrabold leading-tight mb-3">Sometimes<br />your hands<br />are the shutter.</h2>
            <p className="text-gray-600 text-[13px] mb-6 max-w-xs">Raise your hand. SmileOn detects an open palm and triggers a countdown before capturing the photo.</p>
            <span className="bg-black text-white text-[11px] font-bold px-3.5 py-1.5 rounded-full">Prototype / Coming Soon</span>
            <div className="mt-8 flex gap-2">
              {["✋","3","2","1","📸"].map((s, i) => (
                <div key={i} className="flex-1 aspect-[3/5] rounded-xl overflow-hidden bg-gray-200 relative flex items-center justify-center">
                  <img src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80" alt="" className="w-full h-full object-cover opacity-70" />
                  <div className="absolute text-3xl font-black text-white drop-shadow-lg">{s}</div>
                </div>
              ))}
            </div>
            <div className="mt-4 flex justify-between text-[10px] text-gray-400 font-semibold px-1">
              <span>Hand detected</span>
              <span>Photo captured!</span>
            </div>
          </div>

          {/* Event Mode */}
          <div className="bg-[#100820] rounded-3xl p-10 text-white min-h-[420px] relative overflow-hidden border border-[#FF3366]/10">
            <div className="absolute top-0 right-0 w-52 h-52 bg-[#FF3366]/15 blur-[70px] rounded-full" />
            <div className="relative z-10">
              <div className="text-[11px] font-extrabold tracking-[0.15em] text-white/40 mb-3 uppercase">Event Mode</div>
              <h2 className="text-[34px] font-extrabold leading-tight mb-4">One event.<br />Hundreds of<br />memories.</h2>
              <p className="text-white/50 text-[13px] mb-8 max-w-xs">Create a photobooth experience for weddings, birthdays, campus events, communities, and brands—without bringing a dedicated booth.</p>
              <button className="bg-[#FF3366] text-white rounded-full px-6 py-2.5 font-bold text-[13px] flex items-center gap-2 w-fit hover:bg-[#e02255] transition-colors">
                Explore Event Mode <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
            {/* Wedding card */}
            <div className="absolute -bottom-4 -right-4 w-[300px] bg-white rounded-2xl p-4 shadow-2xl text-black z-20" style={{ transform: "rotate(-4deg)" }}>
              <div className="text-[11px] font-bold text-gray-700 mb-3">Hana &amp; Simo Wedding</div>
              <div className="flex gap-4 mb-3">
                <div><div className="text-2xl font-black text-[#FF3366]">300</div><div className="text-[9px] text-gray-400 font-bold uppercase">Photo Credits</div></div>
                <div><div className="text-2xl font-black">248</div><div className="text-[9px] text-gray-400 font-bold uppercase">Photos Taken</div></div>
              </div>
              <div className="flex items-center gap-3 border-t border-gray-100 pt-3">
                <div className="w-14 h-14 bg-gray-200 rounded-lg flex items-center justify-center text-[8px] font-bold text-gray-400">QR CODE</div>
                <div className="text-[10px] font-bold text-gray-600">Scan to Join</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Multi-Device */}
      <section className="relative z-10 py-16 px-8 bg-white/3 backdrop-blur-sm border-y border-white/5">
        <div className="max-w-[1400px] mx-auto">
          <div className="text-[10px] font-extrabold tracking-[0.2em] text-white/30 mb-3 uppercase">Multi-Device Experience</div>
          <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
            <h2 className="text-[40px] font-extrabold leading-tight">One experience.<br />Multiple devices.</h2>
            <button className="bg-[#FF3366] text-white rounded-full px-6 py-2.5 font-bold text-[13px] flex items-center gap-2 w-fit">
              See How It Works <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
          <div className="flex items-center gap-6 overflow-x-auto no-scrollbar pb-4" style={{ scrollbarWidth: "none" }}>
            {[
              { label: "1. Guests join with their phone", phone: true, content: "QR" },
              null,
              { label: "2. Take photos on tablet", tablet: true },
              null,
              { label: "3. Preview on phone", phone: true, content: "photo" },
              null,
              { label: "4. Get your photostrip!", strip: true },
            ].map((step, i) =>
              step === null ? (
                <ArrowRight key={i} className="text-[#FF3366] shrink-0 w-5 h-5" />
              ) : (step as any).strip ? (
                <div key={i} className="flex flex-col items-center shrink-0">
                  <div className="w-20 h-52 bg-white rounded-sm shadow-2xl p-1.5 rotate-[4deg] mb-4">
                    {["photo-1522228115018-d838bcce5c3a","photo-1516585427167-9f4af9627e6c","photo-1529333166437-7750a6dd5a70","photo-1506869640319-baa18047b8ea"].map((id, j) => (
                      <img key={j} src={`https://images.unsplash.com/${id}?auto=format&fit=crop&q=80`} alt="" className="w-full object-cover mb-0.5" style={{height:44}} />
                    ))}
                  </div>
                  <div className="text-[12px] font-bold text-center text-white/80">{(step as any).label}</div>
                </div>
              ) : (step as any).tablet ? (
                <div key={i} className="flex flex-col items-center shrink-0">
                  <div className="w-56 h-40 bg-black rounded-2xl border-4 border-[#222] overflow-hidden mb-4 relative shadow-xl">
                    <img src="https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&q=80" alt="" className="w-full h-full object-cover opacity-80" />
                    <div className="absolute inset-x-0 bottom-2 flex justify-center">
                      <div className="w-10 h-10 rounded-full bg-[#FF3366] shadow-[0_0_15px_#FF3366] border-2 border-white/50" />
                    </div>
                  </div>
                  <div className="text-[12px] font-bold text-center text-white/80">{(step as any).label}</div>
                </div>
              ) : (
                <div key={i} className="flex flex-col items-center shrink-0">
                  <div className="w-24 h-48 bg-black rounded-2xl border-4 border-[#222] overflow-hidden mb-4 shadow-xl flex flex-col">
                    <div className="flex-1 bg-white rounded flex flex-col items-center justify-center gap-2 p-2 m-1">
                      {(step as any).content === "QR" ? (
                        <>
                          <div className="font-bold text-[#FF3366] text-[11px]">Ready!</div>
                          <div className="w-10 h-10 bg-gray-200 rounded" />
                        </>
                      ) : (
                        <>
                          <div className="text-[9px] text-gray-400">Photo 2/4</div>
                          <img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80" alt="" className="w-full object-cover rounded" style={{ height: 60 }} />
                        </>
                      )}
                    </div>
                  </div>
                  <div className="text-[12px] font-bold text-center text-white/80">{(step as any).label}</div>
                </div>
              )
            )}
          </div>
        </div>
      </section>

      {/* Frame Carousel */}
      <section className="bg-white text-black py-16 px-8 relative z-10">
        <div className="max-w-[1400px] mx-auto">
          <div className="text-[10px] font-extrabold tracking-[0.2em] text-gray-400 mb-3 uppercase">Choose Your Frame</div>
          <h2 className="text-[38px] font-extrabold mb-2">Your memory deserves a frame.</h2>
          <p className="text-gray-500 text-[14px] mb-10">A variety of beautiful photostrip frames for every moment, mood, and event.</p>
          <div className="flex gap-6 overflow-x-auto no-scrollbar pb-4 items-end" style={{ scrollbarWidth: "none" }}>
            <button className="shrink-0 w-10 h-10 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-100"><ChevronLeft className="w-4 h-4"/></button>
            {[
              { name: "Romantic Love", bg: "#FFE4E1", color: "#FF3366" },
              { name: "Floral", bg: "#FFF0F5", color: "#FF6699" },
              { name: "Minimal", bg: "#F8F8F8", color: "#333" },
              { name: "Arcade", bg: "#1A1A2E", color: "#00FFCC", dark: true },
              { name: "Pink Diary", bg: "#FFD6E7", color: "#CC0044" },
              { name: "Midnight", bg: "#0D0D2B", color: "#88AAFF", dark: true },
              { name: "Film", bg: "#2C2C2C", color: "#CCCCCC", dark: true },
              { name: "Pastel", bg: "#E8F4F8", color: "#5599CC" },
            ].map((f, i) => (
              <div key={i} className="flex flex-col items-center shrink-0 hover:scale-105 transition-transform cursor-pointer">
                <div className="w-28 h-72 rounded-xl overflow-hidden shadow-lg mb-2" style={{ background: f.bg, padding: 6 }}>
                  {["photo-1522228115018-d838bcce5c3a","photo-1516585427167-9f4af9627e6c","photo-1529333166437-7750a6dd5a70","photo-1506869640319-baa18047b8ea"].map((id, j) => (
                    <img key={j} src={`https://images.unsplash.com/${id}?auto=format&fit=crop&q=80`} alt="" className={`w-full object-cover rounded mb-1 ${f.dark ? '' : ''}`} style={{ height: 59, filter: f.dark ? 'brightness(0.85)' : undefined }} />
                  ))}
                  <div style={{ color: f.color, fontFamily: "Caveat, cursive", fontSize: 13, textAlign: "center", fontWeight: "bold", marginTop: 2 }}>{f.name}</div>
                </div>
                <span className="text-[12px] font-bold text-gray-700">{f.name}</span>
              </div>
            ))}
            <button className="shrink-0 w-10 h-10 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-100"><ChevronRight className="w-4 h-4"/></button>
          </div>
        </div>
      </section>

      {/* Creator Economy & Viral */}
      <section className="relative z-10 py-16 px-8 bg-[#FAF5FF]">
        <div className="max-w-[1400px] mx-auto grid lg:grid-cols-2 gap-5">
          <div className="bg-[#FFF0F8] rounded-3xl p-10 text-black">
            <div className="text-[10px] font-extrabold tracking-[0.2em] text-[#8C40F0] mb-3 uppercase">Made By Creators</div>
            <h2 className="text-[30px] font-extrabold mb-3">Frames can become<br/>a creative economy.</h2>
            <p className="text-gray-600 text-[13px] mb-6 max-w-xs">Creators can design photostrip frames for communities, couples, events, and culture—and earn when their frames are used.</p>
            <button className="bg-[#FF3366] text-white rounded-full px-5 py-2 font-bold text-[12px] mb-8">Coming Next</button>
            <div className="flex items-center gap-2 text-[10px] font-bold text-gray-500 text-center">
              {["Create Frame","Share to Community","People Use It","Creator Earns"].map((s,i,a) => (
                <React.Fragment key={s}>
                  <div className="flex flex-col items-center gap-1 flex-1">
                    <div className="w-12 h-14 bg-white rounded-lg shadow-sm border border-pink-100" />
                    <span>{s}</span>
                  </div>
                  {i < a.length-1 && <ArrowRight className="w-3 h-3 text-gray-300 shrink-0"/>}
                </React.Fragment>
              ))}
            </div>
          </div>

          <div className="bg-white rounded-3xl p-10 text-black shadow-xl">
            <h2 className="text-[30px] font-extrabold mb-3">Every photo can tell<br/>someone else to try SmileOn.</h2>
            <p className="text-gray-500 text-[13px] mb-8">Create. Customize. Share. Discover. Try. Create again.</p>
            <div className="relative h-56 flex items-end justify-center">
              <div className="absolute top-0 left-6 w-10 h-10 bg-black rounded-xl flex items-center justify-center shadow-lg rotate-[-8deg]">
                <svg className="w-5 h-5 text-white fill-white" viewBox="0 0 24 24"><path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.89-4.63V9.32a6.34 6.34 0 0 0-6.33 6.36 6.36 6.36 0 1 0 11.2-4.08v-4.5a8.23 8.23 0 0 0 4.66 1.45V6.69z"/></svg>
              </div>
              <div className="absolute top-0 right-6 w-10 h-10 rounded-xl bg-gradient-to-tr from-yellow-400 via-red-500 to-purple-500 flex items-center justify-center shadow-lg rotate-[8deg]">
                <InstagramIcon className="w-5 h-5 text-white" />
              </div>
              <div className="flex gap-3 items-end">
                <div className="w-20 h-44 bg-pink-50 rounded rotate-[-5deg] shadow border-4 border-white overflow-hidden"><img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80" alt="" className="w-full h-full object-cover" /></div>
                <div className="w-20 h-52 bg-pink-50 rounded z-10 shadow-xl border-4 border-white overflow-hidden"><img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80" alt="" className="w-full h-full object-cover" /></div>
                <div className="w-20 h-44 bg-pink-50 rounded rotate-[5deg] shadow border-4 border-white overflow-hidden"><img src="https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80" alt="" className="w-full h-full object-cover" /></div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Why Onchain */}
      <section className="relative z-10 py-16 px-8 bg-[#F8F4FF]">
        <div className="max-w-[1400px] mx-auto">
          <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-12">
            <div className="max-w-2xl">
              <div className="text-[10px] font-extrabold tracking-[0.2em] text-[#FF3366] mb-3 uppercase">Why Onchain?</div>
              <h2 className="text-[38px] font-extrabold text-black mb-4">Blockchain,<br/>where it actually helps.</h2>
              <p className="text-gray-600 text-[14px]">SmileOn keeps the blockchain underneath the experience, so people can focus on their memories instead of wallets and transactions.</p>
            </div>
            <button className="bg-[#110B29] text-white rounded-full px-5 py-2.5 font-bold text-[13px] flex items-center gap-2 shrink-0">
              <MonadIcon /> Built on Monad
            </button>
          </div>
          <div className="grid md:grid-cols-3 gap-5 text-black">
            {[
              { n: "01", title: "Payments", desc: "Simple onchain payments for premium experiences and event credits." },
              { n: "02", title: "Digital Ownership", desc: "Memories can become persistent digital objects instead of disappearing into a gallery." },
              { n: "03", title: "Creator Economy", desc: "Future creator experiences can use programmable ownership and monetization." },
            ].map(p => (
              <div key={p.n} className="bg-white rounded-2xl p-7 shadow-sm border border-purple-100 flex gap-4">
                <div className="w-11 h-11 bg-[#FF3366]/10 rounded-xl flex items-center justify-center shrink-0">
                  <Check className="w-5 h-5 text-[#FF3366]" />
                </div>
                <div>
                  <div className="font-extrabold mb-1">{p.n}. {p.title}</div>
                  <div className="text-[12px] text-gray-500 leading-relaxed">{p.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Banner */}
      <section className="relative z-10 py-24 px-8 bg-[#0D0010] overflow-hidden">
        <div className="absolute inset-0 bg-[#FF3366]/15 blur-[120px] pointer-events-none" />
        <div className="max-w-[1400px] mx-auto relative z-10 grid md:grid-cols-3 gap-8 items-center">
          <div className="hidden md:flex items-center gap-3 relative h-64">
            <div className="absolute left-0 top-0 w-32 h-60 bg-white rounded p-2 pb-6 shadow-2xl rotate-[-12deg] z-10 overflow-hidden">
              <img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80" alt="" className="w-full h-full object-cover rounded" />
            </div>
            <div className="absolute left-14 top-6 w-32 h-60 bg-[#FFE4E1] rounded p-2 pb-6 shadow-2xl rotate-[4deg] z-20 overflow-hidden">
              <img src="https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80" alt="" className="w-full h-full object-cover rounded" />
            </div>
          </div>

          <div className="text-center">
            <h2 className="text-[42px] font-extrabold leading-tight mb-4">Your next memory<br/>is one tap away.</h2>
            <p className="text-white/50 text-[15px] mb-8">Bring SmileOn with you.</p>
            <div className="flex flex-col sm:flex-row gap-3 justify-center">
              <AppStoreButton type="google" />
              <AppStoreButton type="apple" />
            </div>
          </div>

          <div className="hidden md:flex items-center justify-center relative h-64">
            <motion.div
              animate={{ y: [-6, 6, -6] }}
              transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
              className="w-56 h-44 bg-white/5 backdrop-blur-md rounded-2xl border border-white/15 glow-pink flex items-center justify-center shadow-[0_0_40px_rgba(255,51,102,0.25)]"
            >
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-[#FF3366] to-[#FF88AA] rotate-45 flex items-center justify-center shadow-lg">
                <Heart className="w-10 h-10 text-white fill-white -rotate-45" />
              </div>
            </motion.div>
            <div className="absolute -right-4 -bottom-4">
              <p style={{ fontFamily: "Caveat, cursive", fontSize: 22, color: "#FF88AA", lineHeight: 1.4 }}>
                Capture<br/>Print<br/>Share ♡
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-black border-t border-white/10 py-10 px-8 relative z-10">
        <div className="max-w-[1400px] mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <Heart className="w-5 h-5 text-[#FF3366] fill-[#FF3366]" />
              <span className="font-extrabold text-[16px]">SmileOn</span>
            </div>
            <div className="text-[11px] text-white/30 mb-1">Capture. Print. Share.</div>
            <div className="text-[10px] text-white/20">© 2026 SmileOn. All rights reserved.</div>
          </div>
          <nav className="flex gap-6 text-[12px] font-semibold text-white/40">
            {["Product","Personal","Events","Frames","About"].map(l => (
              <a key={l} href="#" className="hover:text-white transition-colors">{l}</a>
            ))}
          </nav>
          <div className="flex flex-col items-end gap-2">
            <div className="flex gap-4 text-[11px] text-white/40">
              <a href="#" className="flex items-center gap-1.5 hover:text-white transition-colors"><InstagramIcon className="w-3.5 h-3.5" /> @smileon.app</a>
              <a href="#" className="flex items-center gap-1.5 hover:text-white transition-colors"><Mail className="w-3.5 h-3.5" /> smileonapps@gmail.com</a>
            </div>
            <div className="flex items-center gap-1.5 text-[10px] text-white/25">
              <MonadIcon /> Built on Monad
            </div>
          </div>
        </div>
      </footer>

    </div>
  );
}
