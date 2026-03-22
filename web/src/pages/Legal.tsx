import React from 'react';
import { Folder } from 'lucide-react';
import { Link } from 'react-router-dom';

const Legal: React.FC = () => {
  return (
    <div className="min-h-screen bg-notty-bg text-white font-sans">
      <nav className="w-full max-w-4xl mx-auto px-6 py-5 flex items-center justify-between">
        <Link to="/" className="flex items-center gap-2 text-white font-medium">
          <Folder size={18} className="text-notty-indigo-light" />
          Notty
        </Link>
      </nav>

      <main className="w-full max-w-2xl mx-auto px-6 pt-12 pb-24">
        <h1 className="text-3xl font-semibold mb-2">Legal Notice</h1>
        <p className="text-white/30 text-sm mb-12">Last updated: March 2026</p>

        <div className="space-y-8 text-white/60 leading-relaxed">
          <section>
            <h2 className="text-white font-medium mb-2">Publisher</h2>
            <p>Notty is published by NovationLabs, an open-source organization hosted on GitHub.</p>
          </section>

          <section>
            <h2 className="text-white font-medium mb-2">License</h2>
            <p>Notty is released under the <a href="https://github.com/NovationLabs/Notty/blob/main/LICENSE" target="_blank" rel="noreferrer" className="text-notty-indigo-light hover:text-white transition-colors">MIT License</a>. You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software.</p>
          </section>

          <section>
            <h2 className="text-white font-medium mb-2">Disclaimer</h2>
            <p>Notty is provided "as is", without warranty of any kind, express or implied. NovationLabs shall not be liable for any claim, damages, or other liability arising from the use of the software.</p>
          </section>

          <section>
            <h2 className="text-white font-medium mb-2">Third-party components</h2>
            <p>DMG packaging uses <a href="https://github.com/saihgupr/DMGMaker" target="_blank" rel="noreferrer" className="text-notty-indigo-light hover:text-white transition-colors">DMGMaker</a> by @saihgupr, also released under MIT.</p>
          </section>

          <section>
            <h2 className="text-white font-medium mb-2">Contact</h2>
            <p>For any legal inquiry, open an issue on <a href="https://github.com/NovationLabs/Notty/issues" target="_blank" rel="noreferrer" className="text-notty-indigo-light hover:text-white transition-colors">GitHub</a>.</p>
          </section>
        </div>
      </main>

      <footer className="w-full max-w-4xl mx-auto px-6 py-8 border-t border-white/[0.06]">
        <p className="text-white/20 text-sm text-center">&copy; 2026 NovationLabs</p>
      </footer>
    </div>
  );
};

export default Legal;
