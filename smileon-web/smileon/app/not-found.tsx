import NotFoundView from "./notfound/404-notfound";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "404 - Momen Belum Dijepret | SmileOn",
  description: "Halaman yang kamu tuju tidak ditemukan atau belum didefinisikan.",
};

export default function NotFound() {
  return <NotFoundView />;
}
