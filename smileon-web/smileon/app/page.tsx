"use client";

import React, { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { 
  Heart, Camera, Calendar, Image as ImageIcon, Link as LinkIcon,
  Check, ArrowRight, Mail, ChevronLeft, ChevronRight, Play
} from "lucide-react";
import Image from "next/image";


const InstagramIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <rect x="2" y="2" width="20" height="20" rx="5" ry="5"></rect>
    <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"></path>
    <line x1="17.5" y1="6.5" x2="17.51" y2="6.5"></line>
  </svg>
);

// Reusable Components
const Section = ({ children, className = "" }: { children: React.ReactNode, className?: string }) => (
  <section className={`py-16 md:py-24 px-6 md:px-12 max-w-7xl mx-auto w-full ${className}`}>
    {children}
  </section>
);

const Badge = ({ children, icon: Icon, active = false }: { children: React.ReactNode, icon?: any, active?: boolean }) => (
  <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold tracking-wide uppercase border ${active ? 'bg-white text-black border-white' : 'glass text-gray-300'}`}>
    {Icon && <Icon className="w-3.5 h-3.5" />}
    {children}
  </div>
);

const AppStoreButton = ({ type }: { type: 'apple' | 'google' }) => (
  <button className="glass hover:bg-white/10 transition-colors rounded-xl px-4 py-2.5 flex items-center gap-3 border border-white/20">
    {type === 'apple' ? (
      <svg className="w-6 h-6 fill-white" viewBox="0 0 24 24"><path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.04 2.26-.8 3.59-.72 1.58.11 2.82.85 3.55 2.11-2.91 1.62-2.45 5.5.47 6.74-.69 1.63-1.6 3.19-2.69 4.04zm-4.71-13.4c.16-2.53 2.16-4.5 4.54-4.88-.41 2.65-2.58 4.47-4.54 4.88z"/></svg>
    ) : (
      <svg className="w-6 h-6" viewBox="0 0 24 24"><path fill="#EA4335" d="M3.774 2.057a1.996 1.996 0 00-.774 1.582v16.721c0 .647.3 1.22.774 1.583L13 12 3.774 2.057z"/><path fill="#FBBC04" d="M16.592 15.545l-3.592-3.545 3.592-3.545L21.43 11.2c.76.41.76 1.19 0 1.6l-4.838 2.745z"/><path fill="#34A853" d="M3.774 20.362L13 12l3.592 3.545 4.838 2.745c-.44.25-1.03.31-1.608-.03l-16.048-9.9z" transform="matrix(1 0 0 -1 0 24)"/><path fill="#4285F4" d="M3.774 3.638L13 12l3.592-3.545 4.838-2.745c-.44-.25-1.03-.31-1.608.03l-16.048 9.9z"/></svg>
    )}
    <div className="text-left">
      <div className="text-[10px] text-gray-400 font-medium">
        {type === 'apple' ? 'Download on the' : 'Get it on'}
      </div>
      <div className="text-sm font-semibold leading-tight">
        {type === 'apple' ? 'App Store' : 'Google Play'}
      </div>
    </div>
    <ArrowRight className="w-4 h-4 ml-2 text-gray-400" />
  </button>
);

export default function Home() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  if (!mounted) return null;

  return (
    <div className="relative overflow-hidden selection:bg-brand-pink selection:text-white">
      {/* Background Effects */}
      <div className="fixed inset-0 z-[-1] bg-[#0A0510]">
        <div className="absolute top-[-20%] left-[-10%] w-[70vw] h-[70vw] rounded-full bg-brand-pink/20 blur-[120px] mix-blend-screen pointer-events-none" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[60vw] h-[60vw] rounded-full bg-brand-purple/20 blur-[120px] mix-blend-screen pointer-events-none" />
        <div className="absolute top-[40%] left-[60%] w-[40vw] h-[40vw] rounded-full bg-[#FF3366]/10 blur-[100px] pointer-events-none" />
        <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/stardust.png')] opacity-30 pointer-events-none" />
      </div>

      {/* Navbar */}
      <header className="fixed top-0 w-full z-50 glass border-b-0 border-white/5 bg-black/40">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Heart className="text-brand-pink fill-brand-pink w-6 h-6" />
            <span className="text-xl font-bold tracking-tight">SmileOn</span>
          </div>
          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-gray-300">
            <a href="#" className="hover:text-white transition-colors">Product</a>
            <a href="#" className="hover:text-white transition-colors">Personal</a>
            <a href="#" className="hover:text-white transition-colors">Events</a>
            <a href="#" className="hover:text-white transition-colors">Frames</a>
            <a href="#" className="hover:text-white transition-colors">About</a>
          </nav>
          <div className="flex items-center gap-4">
            <a href="#" className="hidden sm:block text-gray-400 hover:text-white transition-colors">
              <InstagramIcon className="w-5 h-5" />
            </a>
            <button className="bg-gradient-brand text-white px-5 py-2.5 rounded-full text-sm font-semibold hover:shadow-[0_0_15px_rgba(255,51,102,0.6)] transition-shadow flex items-center gap-2">
              Download App <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <main className="pt-32 pb-16 md:pt-48 md:pb-24 px-6 max-w-7xl mx-auto w-full relative">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left Content */}
          <div className="relative z-10">
            <div className="flex flex-wrap gap-3 mb-6">
              <Badge active>ONCHAIN PHOTOBOOTH</Badge>
              <Badge>💠 Built on Monad</Badge>
            </div>
            
            <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight leading-[1.1] mb-6">
              Make a moment.<br />
              Make it <span className="text-gradient">SmileOn.</span>
            </h1>
            
            <p className="text-lg md:text-xl text-gray-300 mb-10 max-w-lg leading-relaxed">
              Capture, customize, and share your memories — anytime, anywhere.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-4 mb-12">
              <AppStoreButton type="google" />
              <AppStoreButton type="apple" />
            </div>

            <div className="flex items-center gap-4">
              <div className="flex -space-x-3">
                {[1,2,3,4].map(i => (
                  <div key={i} className="w-10 h-10 rounded-full border-2 border-[#0A0510] bg-gray-600 overflow-hidden">
                    <img src={`https://i.pravatar.cc/100?img=${i+10}`} alt="user" className="w-full h-full object-cover" />
                  </div>
                ))}
              </div>
              <p className="text-sm text-gray-400 max-w-[200px] leading-tight">
                For couples, friends, creators, events and more.
              </p>
            </div>

            <div className="absolute -left-12 -bottom-16 rotate-[-10deg] opacity-80">
              <p className="font-caveat text-3xl text-brand-lightpink">Photobooth,<br/>without<br/>the booth. ♡</p>
            </div>
          </div>

          {/* Right Content - 3D Mockup Area */}
          <div className="relative h-[600px] w-full hidden lg:block perspective-1000">
            {/* Ribbon */}
            <motion.div 
              animate={{ rotate: 360 }}
              transition={{ duration: 60, repeat: Infinity, ease: "linear" }}
              className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[140%] h-[140%] rounded-full border border-brand-pink/30 border-dashed opacity-50"
            />
            
            <motion.div 
              initial={{ y: 20, opacity: 0, rotateY: 15, rotateX: 10, rotateZ: -5 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ duration: 1, delay: 0.2 }}
              className="absolute top-[10%] left-[20%] w-[320px] h-[650px] bg-black rounded-[40px] border-4 border-gray-800 shadow-2xl glow-pink overflow-hidden z-20"
              style={{ transformStyle: "preserve-3d" }}
            >
              <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1621252179027-94459d278660?auto=format&fit=crop&q=80')] bg-cover bg-center opacity-80"></div>
              {/* Phone UI overlay */}
              <div className="absolute inset-0 flex flex-col justify-between p-6">
                <div className="flex justify-between items-center text-white">
                  <ChevronLeft className="w-6 h-6" />
                  <span className="font-bold">SmileOn</span>
                  <InstagramIcon className="w-5 h-5" />
                </div>
                <div className="flex justify-center mb-8">
                  <div className="w-20 h-20 rounded-full border-4 border-brand-pink flex items-center justify-center backdrop-blur-sm bg-white/10">
                    <div className="w-16 h-16 rounded-full bg-brand-pink shadow-[0_0_20px_#ff3366]"></div>
                  </div>
                </div>
              </div>
            </motion.div>

            {/* Floating Photostrips */}
            <motion.div 
              animate={{ y: [-10, 10, -10], rotate: [-10, -8, -10] }}
              transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
              className="absolute top-[5%] right-[10%] w-[120px] bg-white p-2 rounded-sm shadow-xl z-10 rotate-[-10deg]"
            >
               <div className="flex flex-col gap-2">
                 <img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80&w=200&h=200" className="w-full h-[100px] object-cover grayscale" />
                 <img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80&w=200&h=200" className="w-full h-[100px] object-cover grayscale" />
                 <img src="https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80&w=200&h=200" className="w-full h-[100px] object-cover grayscale" />
                 <div className="text-[10px] text-center text-black font-bold pt-1">SmileOn</div>
               </div>
            </motion.div>
            
            <motion.div 
              animate={{ y: [10, -10, 10], rotate: [15, 12, 15] }}
              transition={{ duration: 6, repeat: Infinity, ease: "easeInOut", delay: 1 }}
              className="absolute bottom-[20%] -left-[10%] w-[140px] bg-white p-2 pb-6 rounded-sm shadow-xl z-30 rotate-[15deg]"
            >
               <div className="flex flex-col gap-2">
                 <img src="https://images.unsplash.com/photo-1506869640319-baa18047b8ea?auto=format&fit=crop&q=80&w=200&h=200" className="w-full h-[120px] object-cover" />
                 <img src="https://images.unsplash.com/photo-1523824922871-d6f1a15151f1?auto=format&fit=crop&q=80&w=200&h=200" className="w-full h-[120px] object-cover" />
                 <div className="text-xs text-center text-brand-pink font-caveat font-bold pt-2 text-xl">Love</div>
               </div>
            </motion.div>

            <div className="absolute right-0 top-[60%] opacity-80">
              <p className="font-caveat text-3xl text-brand-lightpink text-right">Your<br/>Memories<br/>Live On ♡</p>
            </div>
          </div>
        </div>
      </main>

      {/* Feature Ribbon */}
      <div className="border-y border-white/10 bg-black/50 backdrop-blur-md relative z-20">
        <div className="max-w-7xl mx-auto px-6 py-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
          {[
            { icon: Camera, title: "Personal Mode", desc: "Take photos with your partner, friends, or yourself." },
            { icon: Calendar, title: "Event Mode", desc: "Create a photobooth for any event." },
            { icon: ImageIcon, title: "Creator Frames", desc: "Unique frames by creators and communities." },
            { icon: LinkIcon, title: "Onchain Ownership", desc: "Your memories, powered by Monad." },
          ].map((feat, i) => (
            <div key={i} className="flex gap-4">
              <div className="w-12 h-12 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center shrink-0 text-brand-pink">
                <feat.icon className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-bold mb-1">{feat.title}</h3>
                <p className="text-sm text-gray-400 leading-snug">{feat.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Why SmileOn & Personal Mode (Split) */}
      <Section className="grid lg:grid-cols-2 gap-6 relative z-10">
        {/* Light Card */}
        <div className="bg-[#FFF0F5] rounded-3xl p-10 md:p-14 text-black relative overflow-hidden flex flex-col justify-between">
          <div className="relative z-10 mb-12">
            <div className="text-brand-pink text-xs font-bold tracking-widest mb-4">WHY SMILEON</div>
            <h2 className="text-3xl md:text-4xl font-extrabold mb-6 leading-tight">Photobooths shouldn't belong to a machine.</h2>
            <p className="text-gray-700 mb-8 text-lg">
              Traditional photobooths are tied to expensive hardware, locations, and setup. SmileOn turns devices people already have into a photobooth experience.
            </p>
            <button className="bg-brand-pink text-white px-6 py-3 rounded-full font-bold flex items-center gap-2 hover:bg-brand-lightpink transition-colors w-fit">
              Learn More <ArrowRight className="w-4 h-4" />
            </button>
          </div>
          
          <div className="relative h-64 bg-white/50 rounded-2xl border border-pink-100 flex items-center p-6 gap-4">
            <div className="w-1/2 grayscale opacity-50 flex flex-col gap-2 text-sm font-semibold">
              <div className="p-2 border border-gray-200 rounded">x Machine</div>
              <div className="p-2 border border-gray-200 rounded">x Location</div>
              <div className="p-2 border border-gray-200 rounded">x Setup</div>
            </div>
            <div className="absolute left-1/2 -translate-x-1/2 w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center z-10 text-brand-pink">
              <ArrowRight className="w-5 h-5" />
            </div>
            <div className="w-1/2 text-brand-pink flex flex-col gap-2 text-sm font-bold pl-6">
              <div className="flex gap-2 items-center"><Check className="w-4 h-4"/> Phone / Tablet</div>
              <div className="flex gap-2 items-center"><Check className="w-4 h-4"/> Anywhere</div>
              <div className="flex gap-2 items-center"><Check className="w-4 h-4"/> Instant setup</div>
            </div>
          </div>
        </div>

        {/* Dark Card */}
        <div className="bg-[#120A1D] rounded-3xl p-10 md:p-14 border border-brand-pink/20 relative overflow-hidden">
           <div className="absolute top-0 right-0 w-64 h-64 bg-brand-pink/10 blur-[80px] rounded-full"></div>
           <div className="relative z-10">
            <div className="text-gray-400 text-xs font-bold tracking-widest mb-4">PERSONAL MODE</div>
            <h2 className="text-3xl md:text-4xl font-extrabold mb-6 leading-tight">For the moments you want to keep.</h2>
            <p className="text-gray-400 mb-8 text-lg max-w-sm">
              Take photos, choose a frame, customize the look, and turn a few seconds into a memory.
            </p>
            <button className="border-2 border-brand-pink text-brand-pink px-6 py-3 rounded-full font-bold flex items-center gap-2 hover:bg-brand-pink hover:text-white transition-colors w-fit mb-12">
              Explore Personal Mode <ArrowRight className="w-4 h-4" />
            </button>
          </div>

          <div className="absolute right-[-10%] bottom-[-10%] w-[300px] h-[400px] bg-black rounded-3xl border-4 border-gray-800 shadow-2xl rotate-[-5deg] overflow-hidden">
             <div className="flex gap-2 h-full overflow-hidden p-4 pt-12">
               <div className="w-1/2 h-full bg-[#FFE4E1] rounded-lg p-1 flex flex-col gap-1 relative shadow-sm">
                 <img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80&w=200&h=300" className="w-full h-[30%] object-cover rounded" />
                 <img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80&w=200&h=300" className="w-full h-[30%] object-cover rounded" />
                 <img src="https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80&w=200&h=300" className="w-full h-[30%] object-cover rounded" />
                 <span className="text-[10px] text-center text-pink-500 font-caveat font-bold mt-1">Romantic</span>
               </div>
               <div className="w-1/2 h-full bg-[#1A1A2E] rounded-lg p-1 flex flex-col gap-1 relative shadow-sm mt-4">
                 <img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80&w=200&h=300" className="w-full h-[30%] object-cover rounded grayscale" />
                 <img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80&w=200&h=300" className="w-full h-[30%] object-cover rounded grayscale" />
                 <img src="https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80&w=200&h=300" className="w-full h-[30%] object-cover rounded grayscale" />
                 <span className="text-[10px] text-center text-blue-300 font-caveat font-bold mt-1">Midnight</span>
               </div>
             </div>
          </div>
        </div>
      </Section>

      {/* Gesture & Event Split */}
      <Section className="grid lg:grid-cols-2 gap-6 pt-0">
        {/* Gesture Capture */}
        <div className="bg-[#FDF2F8] rounded-3xl p-10 text-black relative">
           <div className="text-pink-500 text-xs font-bold tracking-widest mb-4">GESTURE CAPTURE</div>
           <h2 className="text-3xl font-extrabold mb-4">Sometimes your hands are the shutter.</h2>
           <p className="text-gray-700 mb-8 max-w-md">Raise your hand. SmileOn detects an open palm and triggers a countdown before capturing the photo.</p>
           <Badge active>Prototype / Coming Soon</Badge>
           
           <div className="mt-12 flex items-center justify-between gap-2 overflow-hidden">
             {[5,3,2,1].map((step, i) => (
                <div key={i} className="flex-1 aspect-[3/4] bg-gray-200 rounded-lg relative overflow-hidden">
                  <img src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80" className="w-full h-full object-cover opacity-80" />
                  <div className="absolute inset-0 flex items-center justify-center bg-black/20">
                    <span className="text-4xl font-bold text-white/80">{step === 5 ? '✋' : step}</span>
                  </div>
                </div>
             ))}
           </div>
        </div>

        {/* Event Mode */}
        <div className="bg-[#1A0B2E] rounded-3xl p-10 relative overflow-hidden">
           <div className="text-gray-400 text-xs font-bold tracking-widest mb-4">EVENT MODE</div>
           <h2 className="text-3xl font-extrabold mb-4">One event.<br/>Hundreds of memories.</h2>
           <p className="text-gray-400 mb-8 max-w-sm">Create a photobooth experience for weddings, birthdays, campus events, communities, and brands—without bringing a dedicated booth.</p>
           <button className="bg-brand-pink text-white px-6 py-3 rounded-full font-bold flex items-center gap-2 hover:bg-brand-lightpink transition-colors w-fit">
              Explore Event Mode <ArrowRight className="w-4 h-4" />
           </button>

           <div className="absolute right-[-10%] bottom-[-10%] w-[350px] h-[220px] bg-white rounded-2xl p-4 shadow-2xl rotate-[-5deg] flex">
             <div className="w-2/3 pr-4 border-r border-gray-100 text-black flex flex-col justify-center">
                <h4 className="font-bold text-lg mb-4">Hana & Simo Wedding</h4>
                <div className="flex gap-4">
                  <div>
                    <div className="text-2xl font-black text-brand-pink">300</div>
                    <div className="text-[10px] text-gray-500 uppercase font-bold">Photo Credits</div>
                  </div>
                  <div>
                    <div className="text-2xl font-black">248</div>
                    <div className="text-[10px] text-gray-500 uppercase font-bold">Photos Taken</div>
                  </div>
                </div>
             </div>
             <div className="w-1/3 pl-4 flex flex-col items-center justify-center text-black">
                <div className="w-16 h-16 bg-gray-200 mb-2 rounded flex items-center justify-center">
                  <span className="text-[10px] font-bold text-gray-500">QR CODE</span>
                </div>
                <div className="text-[10px] font-bold">Scan to Join</div>
             </div>
           </div>
        </div>
      </Section>

      {/* Multi-Device Experience */}
      <Section className="border-y border-white/5 bg-white/5 relative z-10 mt-12 text-center md:text-left">
        <div className="text-gray-400 text-xs font-bold tracking-widest mb-4">MULTI-DEVICE EXPERIENCE</div>
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-16 gap-6">
          <div className="max-w-xl">
            <h2 className="text-4xl font-extrabold mb-4">One experience.<br/>Multiple devices.</h2>
            <p className="text-gray-400 text-lg">Use a tablet as the camera, let guests join with their phones, and see the memories come to life on screen.</p>
          </div>
          <button className="bg-brand-pink text-white px-6 py-3 rounded-full font-bold flex items-center justify-center gap-2 w-fit mx-auto md:mx-0">
             See How It Works <ArrowRight className="w-4 h-4" />
          </button>
        </div>

        <div className="flex flex-col md:flex-row items-center justify-between gap-4 overflow-x-auto no-scrollbar pb-8">
           {/* Step 1 */}
           <div className="flex flex-col items-center min-w-[150px]">
             <div className="w-24 h-48 bg-black rounded-xl border-4 border-gray-800 p-2 mb-4 relative">
               <div className="bg-white text-black h-full rounded flex flex-col items-center justify-center p-2 text-center">
                 <span className="font-bold text-brand-pink mb-2">Ready!</span>
                 <div className="w-12 h-12 bg-gray-200 mb-2"></div>
               </div>
             </div>
             <div className="text-sm font-bold text-center">1. Guests join<br/>with their phone</div>
           </div>

           <ArrowRight className="text-brand-pink hidden md:block" />

           {/* Step 2 */}
           <div className="flex flex-col items-center min-w-[250px]">
             <div className="w-64 h-40 bg-black rounded-xl border-4 border-gray-800 p-2 mb-4 relative">
                <img src="https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&q=80" className="w-full h-full object-cover rounded opacity-80" />
                <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-8 h-8 rounded-full bg-brand-pink border-2 border-white"></div>
             </div>
             <div className="text-sm font-bold text-center">2. Take photos<br/>on tablet</div>
           </div>

           <ArrowRight className="text-brand-pink hidden md:block" />

           {/* Step 3 */}
           <div className="flex flex-col items-center min-w-[150px]">
             <div className="w-24 h-48 bg-black rounded-xl border-4 border-gray-800 p-2 mb-4 relative">
                <div className="h-full bg-gray-900 rounded flex flex-col pt-4 items-center">
                  <span className="text-[10px]">Photo 2/4</span>
                  <div className="w-16 h-24 bg-gray-800 mt-2">
                    <img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80" className="w-full h-full object-cover opacity-80" />
                  </div>
                </div>
             </div>
             <div className="text-sm font-bold text-center">3. Preview on<br/>phone</div>
           </div>

           <ArrowRight className="text-brand-pink hidden md:block" />

           {/* Step 4 */}
           <div className="flex flex-col items-center min-w-[150px] relative">
             <div className="w-20 h-56 bg-white p-2 rounded-sm shadow-xl mb-4 rotate-[5deg]">
               <div className="flex flex-col gap-1 h-full">
                 <img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80" className="w-full h-[23%] object-cover" />
                 <img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80" className="w-full h-[23%] object-cover" />
                 <img src="https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80" className="w-full h-[23%] object-cover" />
                 <img src="https://images.unsplash.com/photo-1506869640319-baa18047b8ea?auto=format&fit=crop&q=80" className="w-full h-[23%] object-cover" />
               </div>
             </div>
             <div className="text-sm font-bold text-center">4. Get your<br/>photostrip!</div>
             
             <div className="absolute right-[-80px] top-[20px] hidden lg:block">
               <span className="font-caveat text-xl text-brand-pink">So many<br/>memories ♡</span>
             </div>
           </div>
        </div>
      </Section>

      {/* Choose Your Frame */}
      <Section className="bg-white text-black py-24 max-w-none px-0 overflow-hidden">
        <div className="max-w-7xl mx-auto px-6 mb-12">
          <div className="text-gray-500 text-xs font-bold tracking-widest mb-4">CHOOSE YOUR FRAME</div>
          <h2 className="text-4xl font-extrabold mb-4">Your memory deserves a frame.</h2>
          <p className="text-gray-600 max-w-md">A variety of beautiful photostrip frames for every moment, mood, and event.</p>
        </div>
        
        <div className="flex gap-8 overflow-x-auto px-6 md:px-12 pb-12 pt-4 no-scrollbar items-center">
          <button className="w-12 h-12 rounded-full border border-gray-300 flex items-center justify-center shrink-0 hover:bg-gray-100"><ChevronLeft/></button>
          
          {['Romantic Love', 'Floral', 'Minimal', 'Arcade', 'Pink Diary', 'Midnight', 'Film', 'Pastel'].map((frame, i) => (
             <div key={i} className="flex flex-col items-center shrink-0">
                <div className={`w-32 h-80 rounded-lg p-2 shadow-lg mb-4 flex flex-col gap-2
                  ${i % 2 === 0 ? 'bg-[#FFE4E1]' : 'bg-[#F0F8FF]'}
                  ${i === 3 ? 'bg-[#1A1A2E]' : ''}
                `}>
                  <img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80" className="w-full h-[22%] object-cover rounded" />
                  <img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80" className="w-full h-[22%] object-cover rounded" />
                  <img src="https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80" className="w-full h-[22%] object-cover rounded" />
                  <img src="https://images.unsplash.com/photo-1506869640319-baa18047b8ea?auto=format&fit=crop&q=80" className="w-full h-[22%] object-cover rounded" />
                </div>
                <span className={`font-bold text-sm ${i === 3 ? 'text-gray-800' : 'text-gray-800'}`}>{frame}</span>
             </div>
          ))}

          <button className="w-12 h-12 rounded-full border border-gray-300 flex items-center justify-center shrink-0 hover:bg-gray-100"><ChevronRight/></button>
        </div>
      </Section>

      {/* Creator & Viral */}
      <Section className="grid lg:grid-cols-2 gap-6 bg-[#FAFAFA] text-black max-w-none pt-0">
        <div className="max-w-7xl mx-auto w-full col-span-full grid lg:grid-cols-2 gap-6">
          <div className="bg-[#FFF0F5] rounded-3xl p-10">
            <div className="text-brand-purple text-xs font-bold tracking-widest mb-4">MADE BY CREATORS</div>
            <h2 className="text-3xl font-extrabold mb-4">Frames can become a creative economy.</h2>
            <p className="text-gray-700 mb-8 max-w-sm">Creators can design photostrip frames for communities, couples, events, and culture—and earn when their frames are used.</p>
            <button className="bg-brand-pink text-white px-6 py-2 rounded-full font-bold w-fit mb-12">Coming Next</button>
            
            <div className="flex justify-between items-center text-[10px] font-bold text-center text-gray-800">
               <div><div className="w-16 h-20 bg-white rounded shadow-sm mb-2"></div>Create Frame</div>
               <ArrowRight className="text-gray-300 w-4 h-4"/>
               <div><div className="w-16 h-20 bg-white rounded shadow-sm mb-2"></div>Share</div>
               <ArrowRight className="text-gray-300 w-4 h-4"/>
               <div><div className="w-16 h-20 bg-white rounded shadow-sm mb-2"></div>People Use It</div>
               <ArrowRight className="text-gray-300 w-4 h-4"/>
               <div><div className="w-16 h-20 bg-white rounded shadow-sm mb-2"></div>Creator Earns</div>
            </div>
          </div>

          <div className="bg-white rounded-3xl p-10 shadow-xl shadow-gray-200/50 flex flex-col justify-between">
            <div>
              <h2 className="text-3xl font-extrabold mb-4">Every photo can tell someone else to try SmileOn.</h2>
              <p className="text-gray-600 mb-8">Create. Customize. Share. Discover. Try. Create again.</p>
            </div>
            
            <div className="relative h-64 flex items-end justify-center">
               {/* TikTok / IG Icons floating */}
               <div className="absolute top-10 left-10 w-12 h-12 bg-black rounded-xl text-white flex items-center justify-center rotate-[-10deg] shadow-lg">
                 <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.89-4.63V9.32a6.34 6.34 0 0 0-6.33 6.36 6.36 6.36 0 1 0 11.2-4.08v-4.5a8.23 8.23 0 0 0 4.66 1.45V6.69z"/></svg>
               </div>
               <div className="absolute bottom-10 right-10 w-12 h-12 bg-gradient-to-tr from-yellow-400 via-red-500 to-purple-500 rounded-xl text-white flex items-center justify-center rotate-[10deg] shadow-lg">
                 <InstagramIcon className="w-6 h-6" />
               </div>

               <div className="flex gap-4 items-end">
                 <div className="w-24 h-48 bg-gray-100 rounded rotate-[-5deg] shadow-md border-4 border-white overflow-hidden"><img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80" className="w-full h-full object-cover" /></div>
                 <div className="w-24 h-56 bg-gray-100 rounded z-10 shadow-xl border-4 border-white overflow-hidden"><img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80" className="w-full h-full object-cover" /></div>
                 <div className="w-24 h-48 bg-gray-100 rounded rotate-[5deg] shadow-md border-4 border-white overflow-hidden"><img src="https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?auto=format&fit=crop&q=80" className="w-full h-full object-cover" /></div>
               </div>
            </div>
          </div>
        </div>
      </Section>

      {/* Why Onchain */}
      <Section className="bg-[#FAF7FC] text-black py-24 max-w-none">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-16 gap-6">
             <div className="max-w-xl">
               <div className="inline-block bg-brand-pink/10 text-brand-pink text-xs font-bold tracking-widest px-3 py-1 rounded mb-4">WHY ONCHAIN?</div>
               <h2 className="text-4xl font-extrabold mb-4">Blockchain,<br/>where it actually helps.</h2>
               <p className="text-gray-600 text-lg">SmileOn keeps the blockchain underneath the experience, so people can focus on their memories instead of wallets and transactions.</p>
             </div>
             <button className="bg-[#110B29] text-white px-6 py-3 rounded-full font-bold flex items-center gap-3 w-fit">
               <div className="w-6 h-6 bg-brand-purple rounded-md flex items-center justify-center text-xs">M</div>
               Built on Monad
             </button>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {[
              { title: "01. Payments", desc: "Simple onchain payments for premium experiences and event credits." },
              { title: "02. Digital Ownership", desc: "Memories can become persistent digital objects instead of disappearing into a gallery." },
              { title: "03. Creator Economy", desc: "Future creator experiences can use programmable ownership and monetization." }
            ].map((item, i) => (
               <div key={i} className="bg-white rounded-2xl p-8 shadow-sm border border-purple-100 flex gap-4">
                 <div className="w-12 h-12 bg-brand-pink/10 text-brand-pink rounded-xl flex items-center justify-center shrink-0">
                    <Check className="w-6 h-6" />
                 </div>
                 <div>
                   <h3 className="font-bold mb-2">{item.title}</h3>
                   <p className="text-sm text-gray-600 leading-relaxed">{item.desc}</p>
                 </div>
               </div>
            ))}
          </div>
        </div>
      </Section>

      {/* Bottom CTA */}
      <Section className="py-24 max-w-none relative overflow-hidden bg-[#120A1D]">
        <div className="absolute inset-0 bg-gradient-brand opacity-20 blur-[100px] pointer-events-none"></div>
        
        <div className="max-w-7xl mx-auto px-6 relative z-10 grid md:grid-cols-3 gap-12 items-center">
          
          <div className="relative h-64 hidden md:block">
            <div className="absolute left-0 top-0 w-32 h-64 bg-white p-2 pb-8 rounded shadow-2xl rotate-[-15deg] z-10"><img src="https://images.unsplash.com/photo-1522228115018-d838bcce5c3a?auto=format&fit=crop&q=80" className="w-full h-full object-cover rounded-sm" /></div>
            <div className="absolute left-16 top-8 w-32 h-64 bg-[#FFE4E1] p-2 pb-8 rounded shadow-2xl rotate-[5deg] z-20"><img src="https://images.unsplash.com/photo-1516585427167-9f4af9627e6c?auto=format&fit=crop&q=80" className="w-full h-full object-cover rounded-sm grayscale" /></div>
          </div>

          <div className="text-center">
            <h2 className="text-4xl md:text-5xl font-extrabold mb-6">Your next memory<br/>is one tap away.</h2>
            <p className="text-xl text-gray-300 mb-10">Bring SmileOn with you.</p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <AppStoreButton type="google" />
              <AppStoreButton type="apple" />
            </div>
          </div>

          <div className="relative h-64 hidden md:flex items-center justify-center">
             <div className="w-64 h-48 bg-white/10 backdrop-blur-md rounded-2xl border border-white/20 glow-pink relative flex items-center justify-center">
               <div className="w-24 h-24 rounded-2xl bg-gradient-brand rotate-[45deg] flex items-center justify-center shadow-lg">
                 <Heart className="w-12 h-12 text-white fill-white rotate-[-45deg]" />
               </div>
             </div>
             <div className="absolute right-[-40px] bottom-[-20px]">
               <span className="font-caveat text-3xl text-brand-lightpink text-right">Capture<br/>Print<br/>Share ♡</span>
             </div>
          </div>

        </div>
      </Section>

      {/* Footer */}
      <footer className="bg-black py-12 border-t border-white/10">
        <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-row justify-between items-center gap-8">
          
          <div className="flex flex-col items-center md:items-start">
            <div className="flex items-center gap-2 mb-2">
              <Heart className="text-brand-pink fill-brand-pink w-6 h-6" />
              <span className="text-xl font-bold tracking-tight">SmileOn</span>
            </div>
            <p className="text-xs text-gray-500 mb-4">Capture. Print. Share.</p>
            <p className="text-[10px] text-gray-600">© 2026 SmileOn. All rights reserved.</p>
          </div>

          <nav className="flex flex-wrap justify-center gap-6 text-xs font-semibold text-gray-400">
            <a href="#" className="hover:text-white transition-colors">Product</a>
            <a href="#" className="hover:text-white transition-colors">Personal</a>
            <a href="#" className="hover:text-white transition-colors">Events</a>
            <a href="#" className="hover:text-white transition-colors">Frames</a>
            <a href="#" className="hover:text-white transition-colors">About</a>
          </nav>

          <div className="flex flex-col items-center md:items-end gap-4">
            <div className="flex gap-4">
              <a href="#" className="text-gray-500 hover:text-white flex items-center gap-2 text-xs">
                <InstagramIcon className="w-4 h-4" /> @smileon.app
              </a>
              <a href="#" className="text-gray-500 hover:text-white flex items-center gap-2 text-xs">
                <Mail className="w-4 h-4" /> smileonapps@gmail.com
              </a>
            </div>
            <div className="flex items-center gap-2 text-[10px] text-gray-500">
              <div className="w-4 h-4 bg-brand-purple rounded-sm flex items-center justify-center text-white font-bold">M</div>
              Built on Monad
            </div>
          </div>

        </div>
      </footer>

    </div>
  );
}
