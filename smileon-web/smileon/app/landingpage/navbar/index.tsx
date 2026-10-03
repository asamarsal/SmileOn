"use client";

import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Heart, ArrowRight, Menu, X } from "lucide-react";
import Image from "next/image";

const InstagramIcon = ({ className }: { className?: string }) => (
  <svg
    className={className}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
    <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" />
    <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
  </svg>
);

const NAV_LINKS = ["Product", "Personal", "Events", "Frames", "About"];

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <>
      <header
        className={`fixed top-0 w-full z-50 transition-all duration-500 ${scrolled
          ? "backdrop-blur-2xl bg-black/50 border-b border-white/10 shadow-[0_8px_32px_rgba(0,0,0,0.4)]"
          : "backdrop-blur-xl bg-black/20 border-b border-white/5"
          }`}
      >
        <div className="max-w-[1400px] mx-auto px-6 md:px-8 h-[68px] flex items-center justify-between">
          {/* ── Logo ── */}
          <a href="/" className="flex items-center gap-2.5 group" aria-label="SmileOn Home">
            <Image
              src="/icon/smileon-text.png"
              alt="SmileOn"
              width={90}
              height={26}
              className="object-contain opacity-90 group-hover:opacity-100 transition-opacity"
            />
          </a>

          {/* ── Desktop Nav links ── */}
          <nav
            className="hidden md:flex items-center gap-8 text-[13px] font-medium text-white/60"
            aria-label="Main navigation"
          >
            {NAV_LINKS.map((link) => (
              <a
                key={link}
                href={`#${link.toLowerCase()}`}
                className="relative hover:text-white transition-colors group"
              >
                {link}
                <span className="absolute -bottom-0.5 left-0 w-0 h-[1.5px] bg-[#FF3366] rounded-full group-hover:w-full transition-all duration-300" />
              </a>
            ))}
          </nav>

          {/* ── Right CTA ── */}
          <div className="flex items-center gap-3">
            <a
              href="https://instagram.com/smileon.app"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:opacity-80 transition-opacity hidden sm:flex items-center justify-center"
              aria-label="SmileOn Instagram"
            >
              <Image 
                src="/icon/instagram-icon-only.png" 
                alt="Instagram" 
                width={38} 
                height={38} 
                className="object-contain"
              />
            </a>

            <motion.button
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.97 }}
              className="bg-gradient-to-r from-[#FF3366] to-[#FF5C8D] hover:from-[#ff245d] hover:to-[#ff4d80] text-white text-[13px] font-bold px-5 py-2.5 rounded-full flex items-center gap-1.5 shadow-[0_0_24px_rgba(255,51,102,0.45)] transition-all"
              aria-label="Download SmileOn App"
            >
              Download App <ArrowRight className="w-3.5 h-3.5" />
            </motion.button>

            {/* Mobile menu toggle */}
            <button
              className="md:hidden text-white/60 hover:text-white transition-colors p-1"
              onClick={() => setMobileOpen((v) => !v)}
              aria-label="Toggle mobile menu"
              aria-expanded={mobileOpen}
            >
              {mobileOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </header>

      {/* ── Mobile Menu Drawer ── */}
      <AnimatePresence>
        {mobileOpen && (
          <motion.div
            key="mobile-menu"
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.22, ease: "easeOut" }}
            className="fixed top-[68px] left-0 right-0 z-40 bg-black/90 backdrop-blur-2xl border-b border-white/10 px-6 py-6 md:hidden"
          >
            <nav className="flex flex-col gap-4" aria-label="Mobile navigation">
              {NAV_LINKS.map((link) => (
                <a
                  key={link}
                  href={`#${link.toLowerCase()}`}
                  className="text-[15px] font-semibold text-white/70 hover:text-white transition-colors py-1"
                  onClick={() => setMobileOpen(false)}
                >
                  {link}
                </a>
              ))}
            </nav>

            <div className="mt-6 pt-6 border-t border-white/10 flex items-center gap-4">
              <a
                href="https://instagram.com/smileon.app"
                target="_blank"
                rel="noopener noreferrer"
                className="text-white/40 hover:text-white transition-colors"
              >
                <InstagramIcon className="w-5 h-5" />
              </a>
              <button className="flex-1 bg-gradient-to-r from-[#FF3366] to-[#FF6699] text-white text-[13px] font-bold px-5 py-2.5 rounded-full flex items-center justify-center gap-2">
                Download App <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
