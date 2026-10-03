"use client";

import React, { useRef } from "react";
import dynamic from "next/dynamic";
import { motion } from "framer-motion";
import { ArrowRight, Camera, Calendar, Image as ImageIcon, Link as LinkIcon } from "lucide-react";
import Image from "next/image";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import { ScrollTrigger } from "gsap/ScrollTrigger";

/* ── Lottie JSON imports ────────────────────────────── */
import googlePlayAnim from "@/public/lottie/lp_googleplay_card_loop.json";
import appStoreAnim from "@/public/lottie/lp_appstore_card_loop.json";

gsap.registerPlugin(ScrollTrigger);

/* ── Dynamic LottiePlayer (SSR disabled, typed correctly) ── */
interface LottiePlayerProps {
  src: object | string;
  loop?: boolean | number;
  autoplay?: boolean;
  style?: React.CSSProperties;
  className?: string;
}

const LottiePlayer = dynamic<LottiePlayerProps>(
  () =>
    import("lottie-react").then((mod) => ({
      default: mod.Lottie as any,
    })),
  {
    ssr: false,
    loading: () => null,
  }
);

/* ── Icon helpers ─────────────────────────────────────── */
const MonadIcon = () => (
  <svg className="w-4 h-4 shrink-0" viewBox="0 0 20 20" fill="none">
    <rect width="20" height="20" rx="4" fill="#6B3FE7" />
    <path
      d="M5 14V8l5 4 5-4v6"
      stroke="white"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
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

/* ── Store Button with shine shimmer effect ── */
const StoreButton = ({ type }: { type: "google" | "apple" }) => (
  <motion.a
    href={type === "google" ? "https://play.google.com" : "https://apple.com/app-store"}
    target="_blank"
    rel="noopener noreferrer"
    whileHover={{ scale: 1.03, y: -2 }}
    whileTap={{ scale: 0.98 }}
    aria-label={type === "google" ? "Get it on Google Play" : "Download on the App Store"}
    className="relative flex items-center justify-between gap-4 bg-[#141417] hover:bg-[#1c1c22] border border-white/15 hover:border-white/35 text-white rounded-2xl px-5 py-3 transition-all duration-300 shadow-[0_4px_20px_rgba(0,0,0,0.5)] group overflow-hidden min-w-[195px]"
  >
    {/* Animated Shimmer sweep */}
    <div className="absolute inset-0 -translate-x-full group-hover:translate-x-full transition-transform duration-1000 bg-gradient-to-r from-transparent via-white/12 to-transparent pointer-events-none" />

    <div className="flex items-center gap-3 relative z-10">
      {type === "google" ? <GooglePlayIcon /> : <AppleIcon />}
      <div className="text-left">
        <div className="text-[10px] text-white/50 tracking-wider font-semibold uppercase leading-none mb-1">
          {type === "google" ? "Get it on" : "Download on the"}
        </div>
        <div className="text-[15px] font-bold leading-tight tracking-tight">
          {type === "google" ? "Google Play" : "App Store"}
        </div>
      </div>
    </div>

    <ArrowRight className="w-4 h-4 text-white/40 group-hover:text-white group-hover:translate-x-0.5 transition-all relative z-10 shrink-0" />
  </motion.a>
);

/* ── Floating Stars / Sparkles decoration ───────────── */
const SPARKLES = [
  { top: "14%", left: "10%", size: 14, delay: 0, dur: 2.6 },
  { top: "8%", left: "45%", size: 10, delay: 0.7, dur: 3.1 },
  { top: "25%", right: "8%", size: 16, delay: 1.2, dur: 2.9 },
  { top: "68%", left: "4%", size: 12, delay: 1.8, dur: 3.3 },
  { bottom: "25%", right: "6%", size: 12, delay: 2.1, dur: 3.6 },
  { top: "52%", left: "48%", size: 9, delay: 0.9, dur: 3.8 },
] as const;

/* ─────────────────────────────────────────────────────
   TOP CONTENT  —  Hero section + integrated feature row
───────────────────────────────────────────────────── */
export default function TopContent() {
  const containerRef = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    // Parallax scroll animations for the right stage elements
    const tl = gsap.timeline({
      scrollTrigger: {
        trigger: containerRef.current,
        start: "top 25%", // start when top of container hits 25% of viewport
        end: "bottom top", // end when bottom of container hits top of viewport
        scrub: 1, // smooth scrubbing, takes 1 second to "catch up" to scrollbar
      },
    });

    // Move elements at different speeds/rotations based on scroll
    tl.to(".gsap-glass", { y: -60, rotate: -20 }, 0);
    tl.to(".gsap-photostrip", { y: -80, rotate: 1 }, 0);
    tl.to(".gsap-cube", { y: -100, rotate: 8 }, 0);
    tl.to(".gsap-note", { y: -40, rotate: -8 }, 0);
    tl.to(".gsap-monad", { y: -50, rotate: -2 }, 0);
    tl.to(".gsap-photobox", { y: -40, rotate: -2 }, 0);
    tl.to(".gsap-ring-1", { rotate: 25 }, 0);
    tl.to(".gsap-ring-2", { rotate: -25 }, 0);
    tl.to(".gsap-phone", { y: -30 }, 0);
  }, { scope: containerRef });

  return (
    <section
      className="relative z-10 pt-[105px] md:pt-[120px] pb-12 overflow-hidden"
      aria-label="Hero"
    >


      {/* ── Floating Sparkles ── */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden" aria-hidden="true">
        {SPARKLES.map((s, i) => (
          <motion.div
            key={i}
            style={{
              position: "absolute",
              top: (s as any).top,
              left: (s as any).left,
              right: (s as any).right,
              bottom: (s as any).bottom,
            }}
            animate={{ opacity: [0.3, 1, 0.3], scale: [0.85, 1.25, 0.85] }}
            transition={{ duration: s.dur, repeat: Infinity, delay: s.delay, ease: "easeInOut" }}
            className="text-white/60"
          >
            <svg
              width={s.size}
              height={s.size}
              viewBox="0 0 24 24"
              fill="currentColor"
              className="drop-shadow-[0_0_8px_rgba(255,255,255,0.8)]"
            >
              <path d="M12 0L14.6 9.4L24 12L14.6 14.6L12 24L9.4 14.6L0 12L9.4 9.4L12 0Z" />
            </svg>
          </motion.div>
        ))}
      </div>

      {/* ══════════════════════════════════════════════════
          HERO MAIN GRID: Left copy & Right 3D Visual Stage
      ══════════════════════════════════════════════════ */}
      <div className="max-w-[1400px] mx-auto px-6 md:px-8 grid grid-cols-1 lg:grid-cols-[1fr_1.15fr] gap-6 lg:gap-8 items-center min-h-[640px]">

        {/* ── Left Column: Headline & CTA ──────────────── */}
        <motion.div
          initial={{ opacity: 0, y: 25 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, ease: "easeOut" }}
          className="relative z-10 pt-4 pb-8 lg:pb-12 self-start mt-4 lg:mt-8"
        >
          {/* Pill Badges (dark translucent pill matching reference) */}
          <div className="flex flex-wrap items-center gap-2.5 mb-7">
            <span className="bg-white/[0.08] backdrop-blur-md border border-white/20 text-white/90 text-[11px] font-bold tracking-[0.12em] px-4 py-1.5 rounded-full uppercase shadow-sm">
              ONCHAIN PHOTOBOOTH
            </span>
            <span className="bg-white/[0.08] backdrop-blur-md border border-white/20 px-3.5 py-1.5 rounded-full flex items-center shadow-sm">
              <Image
                src="/icon/monad-logo-textandicon.svg"
                alt="Built on Monad"
                width={85}
                height={18}
                className="object-contain"
              />
            </span>
          </div>

          {/* Headline with sparkle */}
          <h1 className="text-5xl sm:text-6xl lg:text-[70px] font-extrabold tracking-tight leading-[1.05] mb-6">
            Make a moment.<br />
            Make it{" "}
            <span className="bg-gradient-to-r from-[#FF3366] via-[#FF5C8D] to-[#FFA3BA] bg-clip-text text-transparent drop-shadow-[0_4px_24px_rgba(255,51,102,0.4)]">
              SmileOn.
            </span>
            <span className="inline-block ml-2 text-[#FF5C8D] text-3xl md:text-4xl align-middle animate-pulse">
              ✦
            </span>
          </h1>

          {/* Subtitle */}
          <p className="text-[17px] text-white/65 leading-relaxed mb-8 max-w-md">
            Capture, customize, and share your memories —<br />
            anytime, anywhere.
          </p>

          {/* Store Buttons */}
          <div className="flex flex-col sm:flex-row gap-3.5 mb-8">
            <StoreButton type="google" />
            <StoreButton type="apple" />
          </div>

          {/* Social Proof */}
          <div className="flex items-center gap-4">
            <div className="flex -space-x-2.5" aria-hidden="true">
              {[20, 21, 22, 23].map((n) => (
                <img
                  key={n}
                  src={`https://i.pravatar.cc/80?img=${n}`}
                  alt=""
                  className="w-9 h-9 rounded-full border-2 border-[#0A030C] object-cover"
                />
              ))}
            </div>
            <p className="text-[13px] text-white/60 leading-snug">
              For couples, friends, creators,<br className="hidden sm:inline" /> events and more.
            </p>
          </div>
        </motion.div>

        {/* ── Right Column: 3D Visual Collage Stage ─────── */}
        <div ref={containerRef} className="relative h-[620px] lg:h-[660px] w-full" aria-hidden="true">

          {/* 1. Orbiting Rings (parallax via GSAP) */}
          <div
            className="gsap-ring-1 absolute top-[45%] left-[50%] -translate-x-1/2 -translate-y-1/2 w-[550px] h-[600px] pointer-events-none z-0"
          >
            <Image
              src="/landingpage/lp-circleoval-line.svg"
              alt=""
              fill
              className="object-contain opacity-40"
            />
          </div>

          <div
            className="gsap-ring-2 absolute top-[45%] left-[50%] -translate-x-1/2 -translate-y-1/2 w-[650px] h-[700px] pointer-events-none z-0"
          >
            <Image
              src="/landingpage/lp-circleoval-line-2.svg"
              alt=""
              fill
              className="object-contain opacity-25"
            />
          </div>

          {/* 2. Glass Polaroid Frame (Top Left, behind phone) */}
          <div
            className="gsap-glass absolute top-[2%] left-[2%] lg:left-[5%] w-[240px] lg:w-[280px] z-10 pointer-events-none opacity-90 -rotate-[15deg]"
            style={{ filter: "drop-shadow(0 15px 35px rgba(0,0,0,0.5))" }}
          >
            <Image
              src="/landingpage/lp-glass-frame.svg"
              alt=""
              width={320}
              height={500}
              className="w-full h-auto object-contain"
            />
          </div>

          {/* 3. Photobox Anywhere (Bottom Left of phone) */}
          <div
            className="gsap-photobox absolute bottom-[20%] left-[-15%] lg:left-[5%] w-[110px] lg:w-[130px] z-40 opacity-90 -rotate-[12deg]"
          >
            <Image
              src="/landingpage/lp-photobox-anywhere.svg"
              alt="Photobox anywhere"
              width={115}
              height={145}
              className="w-full h-auto object-contain"
            />
          </div>

          {/* 4. Photostrip (Right Side) */}
          <div
            className="gsap-photostrip absolute top-[-2%] right-[10%] lg:right-[16%] w-[140px] lg:w-[165px] z-20 rotate-[5deg]"
            style={{
              filter: "drop-shadow(0 20px 40px rgba(0,0,0,0.65))",
            }}
          >
            <Image
              src="/landingpage/lp-photostrip-smileon.svg"
              alt="SmileOn couple photostrip"
              width={180}
              height={520}
              className="w-full h-auto object-contain"
            />
          </div>

          {/* 5. Main Phone Mockup (Centerpiece) */}
          <motion.div
            initial={{ y: 30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.8, delay: 0.15 }}
            className="gsap-phone absolute top-[6%] left-[20%] lg:left-[24%] w-[240px] sm:w-[270px] lg:w-[300px] z-30"
            style={{
              filter: "drop-shadow(0 25px 50px rgba(255, 51, 102, 0.35)) drop-shadow(0 10px 25px rgba(0,0,0,0.7))",
            }}
          >
            <Image
              src="/landingpage/lp-phone-smileon.svg"
              alt="SmileOn camera app on phone"
              width={310}
              height={620}
              className="w-full h-auto object-contain"
              priority
            />
          </motion.div>

          {/* 7. 3D Crystal Cube with Glowing Pink Heart */}
          <div
            className="gsap-cube absolute top-[38%] right-[-5%] lg:right-[1%] z-50 w-[110px] lg:w-[130px]"
            style={{ filter: "drop-shadow(0 0 35px rgba(255,51,102,0.5))" }}
          >
            <Image
              src="/landingpage/lp-lovebadge-pinkglow.svg"
              alt="Glowing crystal love badge"
              width={145}
              height={145}
              className="w-full h-auto object-contain"
            />
          </div>

          {/* 9. Sticky Note "Good Memories Onchain ♡" */}
          <div
            className="gsap-note absolute top-[14%] right-[0%] lg:right-[6%] z-25 w-[95px] lg:w-[110px] rotate-[3deg]"
          >
            <Image
              src="/landingpage/lp-notes-goodmemory.svg"
              alt="Good memories onchain note"
              width={115}
              height={110}
              className="w-full h-auto object-contain"
            />
          </div>

          {/* 10. Handwritten Text on Far Right: "Your Memories Live On ♡" */}
          <div
            className="absolute top-[58%] right-[-2%] lg:right-[2%] z-32 text-right pointer-events-none"
            aria-hidden="true"
          >
            <p className="font-caveat text-xl lg:text-2xl text-[#FF88AA] leading-snug drop-shadow-md">
              Your<br />Memories<br />Live On<br />
              <span className="text-[#FF3366] text-3xl">♡</span>
            </p>
          </div>



          {/* 12. Floating Petal (top left of visual stage) */}
          <div className="absolute top-[5%] left-[-5%] w-[70px] pointer-events-none z-15 opacity-70">
            <Image
              src="/landingpage/lp-flower-one-petal.svg"
              alt=""
              width={90}
              height={90}
              className="w-full h-auto object-contain"
            />
          </div>

        </div>
      </div>

      {/* ══════════════════════════════════════════════════
          FEATURE PILLS / CARDS (Integrated at base of hero)
      ══════════════════════════════════════════════════ */}
      <div className="max-w-[1400px] mx-auto px-6 md:px-8 mt-6 lg:mt-8">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            {
              Icon: Camera,
              title: "Personal Mode",
              desc: "Take photos with your partner, friends, or yourself.",
            },
            {
              Icon: Calendar,
              title: "Event Mode",
              desc: "Create a photobooth for any event.",
            },
            {
              Icon: ImageIcon,
              title: "Creator Frames",
              desc: "Unique frames by creators and communities.",
            },
            {
              Icon: LinkIcon,
              title: "Onchain Ownership",
              desc: "Your memories, powered by Monad.",
              hasSparkle: true,
            },
          ].map(({ Icon, title, desc, hasSparkle }, i) => (
            <motion.div
              key={i}
              whileHover={{ y: -3, borderColor: "rgba(255, 51, 102, 0.4)" }}
              className="relative flex items-start gap-4 p-4 md:p-5 rounded-2xl bg-white/[0.04] backdrop-blur-xl border border-white/10 hover:bg-white/[0.07] transition-all group shadow-[0_8px_30px_rgba(0,0,0,0.3)]"
            >
              <div className="w-11 h-11 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-center shrink-0 text-[#FF4D8D] group-hover:scale-105 group-hover:text-[#FF3366] transition-all">
                <Icon className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-bold text-[15px] text-white flex items-center gap-1.5 mb-1">
                  {title}
                  {hasSparkle && (
                    <span className="text-[#FF5C8D] text-sm animate-pulse">✦</span>
                  )}
                </div>
                <div className="text-[12px] text-white/50 leading-relaxed">
                  {desc}
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
