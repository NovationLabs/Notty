import React from 'react';
import { Folder } from 'lucide-react';
import { Link } from 'react-router-dom';

const Privacy: React.FC = () => {
  return (
    <div className="min-h-screen bg-notty-bg text-white font-sans">
      <nav className="w-full max-w-4xl mx-auto px-6 py-5 flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2 text-white font-medium">
          <Folder size={18} className="text-notty-indigo-light" />
          Notty
        </Link>
      </nav>

      <main className="w-full max-w-2xl mx-auto px-6 pt-12 pb-24">
        <h1 className="text-3xl font-semibold mb-2">Privacy Policy</h1>
        <p className="text-white/30 text-sm mb-12">Last updated: March 2026</p>

        <div className="space-y-8 text-white/60 leading-relaxed">
          <section>
            <h2 className="text-white font-medium mb-2">No data collected</h2>
            <p>Notty does not collect, transmit, or store any personal data. All notes are saved locally on your device at <code className="text-notty-indigo-light text-sm">~/.notty.txt</code> and never leave your machine.</p>
          </section>

          <section>
            <h2 className="text-white font-medium mb-2">No network requests</h2>
            <p>The Notty app makes no network requests. It operates entirely offline. No analytics, no crash reporting, no telemetry.</p>
          </section>

          <section>
            <h2 className="text-white font-medium mb-2">This website</h2>
            <p>This website is a static page served via nginx. It does not use cookies, tracking pixels, or any analytics. The only external request is to the GitHub API to display the latest version number.</p>
          </section>

          <section>
            <h2 className="text-white font-medium mb-2">Open source</h2>
            <p>Notty is fully open source. You can audit every line of code on <a href="https://github.com/NovationLabs/Notty" target="_blank" rel="noreferrer" className="text-notty-indigo-light hover:text-white transition-colors">GitHub</a>.</p>
          </section>

          <section>
            <h2 className="text-white font-medium mb-2">Contact</h2>
            <p>Questions? Open an issue on <a href="https://github.com/NovationLabs/Notty/issues" target="_blank" rel="noreferrer" className="text-notty-indigo-light hover:text-white transition-colors">GitHub</a>.</p>
          </section>
        </div>
      </main>

      <footer className="w-full max-w-4xl mx-auto px-6 py-8 border-t border-white/[0.06]">
        <p className="text-white/20 text-sm text-center">&copy; 2026 NovationLabs</p>
      </footer>
    </div>
  );
};

export default Privacy;
