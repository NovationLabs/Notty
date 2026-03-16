import React, { useState, useEffect } from 'react';
import { Download, Terminal, ArrowUpRight, Copy, Check, Folder, Sparkles } from 'lucide-react';

const Home: React.FC = () => {
  const [copied, setCopied] = useState<string | null>(null);
  const [version, setVersion] = useState<string>('v1.1');

  useEffect(() => {
    fetch('https://api.github.com/repos/NovationLabs/Notty/releases/latest')
      .then(res => res.json())
      .then(data => { if (data.tag_name) setVersion(data.tag_name); })
      .catch(() => {});
  }, []);

  const copyCommand = (text: string, id: string = 'default') => {
    navigator.clipboard.writeText(text);
    setCopied(id);
    setTimeout(() => setCopied(null), 2000);
  };

  return (
    <div className="min-h-screen bg-notty-bg text-white">

      {/* ===== HEADER ===== */}
      <header className="w-full max-w-4xl mx-auto px-6 py-8 flex items-center justify-between">
        <a href="/" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
          <Folder size={20} className="text-notty-indigo-light" />
          <span className="text-[15px] font-medium tracking-tight">Notty</span>
        </a>
        <nav className="flex items-center gap-6 text-sm text-white/60">
          <a href="https://github.com/NovationLabs/Notty" target="_blank" rel="noreferrer"
            className="hover:text-white transition-colors flex items-center gap-1">
            GitHub <ArrowUpRight size={12} />
          </a>
          <a href="https://github.com/NovationLabs/Notty#cli" target="_blank" rel="noreferrer"
            className="hover:text-white transition-colors">
            Docs
          </a>
          <a href="https://github.com/NovationLabs/Notty/releases/latest/download/Notty.dmg" target="_blank" rel="noreferrer"
            className="text-white bg-white/10 hover:bg-white/15 px-4 py-1.5 rounded-lg text-sm transition-colors">
            Download
          </a>
        </nav>
      </header>

      {/* ===== HERO ===== */}
      <main className="w-full max-w-4xl mx-auto px-6 pt-10 pb-24">
        <div className="text-center mb-12" id="download">
          <h1 className="text-4xl md:text-5xl font-semibold tracking-tight mb-4">
            Download Notty
          </h1>
          {version && (
            <p className="text-white/40 text-base">
              Version {version.replace(/^v/, '')} &nbsp;·&nbsp;{' '}
              <a href={`https://github.com/NovationLabs/Notty/releases/tag/${version}`}
                target="_blank" rel="noreferrer"
                className="text-notty-indigo-light hover:text-white transition-colors">
                Release Notes
              </a>
            </p>
          )}
        </div>

        {/* ===== INSTALL COMMAND ===== */}
        <div className="mb-14">
          <h2 className="text-lg font-medium mb-4 text-center">Quick Install</h2>
          <div className="bg-notty-surface rounded-xl border border-white/[0.06] p-5 flex items-center justify-between max-w-xl mx-auto">
            <code className="font-mono text-sm text-white/70">
              <span className="text-notty-indigo-light">$</span> brew tap NovationLabs/notty && brew install notty
            </code>
            <button
              onClick={() => copyCommand('brew tap NovationLabs/notty && brew install notty', 'brew')}
              className="text-white/30 hover:text-white transition-colors ml-4 flex-shrink-0">
              {copied === 'brew' ? <Check size={16} className="text-notty-indigo-light" /> : <Copy size={16} />}
            </button>
          </div>
        </div>

        {/* ===== DOWNLOAD CARDS ===== */}
        <div className="grid md:grid-cols-2 gap-6 mb-24">

          {/* macOS Card */}
          <div className="bg-notty-card rounded-2xl border border-white/[0.06] p-10">
            <h2 className="text-xl font-medium mb-3">macOS</h2>
            <p className="text-white/40 text-sm leading-relaxed mb-8">
              Universal binary for Apple Silicon and Intel.
              Requires macOS 13+ (Ventura or later).
            </p>
            <div className="flex flex-col sm:flex-row gap-3">
              <a href="https://github.com/NovationLabs/Notty/releases/latest/download/Notty.dmg"
                target="_blank" rel="noreferrer"
                className="flex items-center justify-center gap-2 bg-notty-accent hover:bg-notty-indigo text-white font-medium px-5 py-3 rounded-xl transition-colors text-sm whitespace-nowrap">
                <Download size={16} />
                Download
              </a>
              <a href="https://github.com/NovationLabs/Notty#build-from-source"
                target="_blank" rel="noreferrer"
                className="flex items-center justify-center gap-2 bg-white/[0.06] hover:bg-white/10 text-white/80 font-medium px-5 py-3 rounded-xl transition-colors text-sm border border-white/[0.06] whitespace-nowrap">
                <Terminal size={16} />
                Build from Source
              </a>
            </div>
          </div>

          {/* Ask Claude Card */}
          <div className="bg-notty-card rounded-2xl border border-white/[0.06] p-10 flex flex-col">
            <div className="flex items-center gap-3 mb-3">
              <img src="/claude.png" alt="Claude" className="w-6 h-6 rounded" />
              <h2 className="text-xl font-medium">Ask Claude Code</h2>
            </div>
            <div className="bg-notty-surface rounded-xl border border-white/[0.06] p-4 flex items-start justify-between gap-3 flex-1">
              <code className="font-mono text-xs text-white/50 leading-relaxed block whitespace-pre-wrap">{'Install Notty, a menu bar notepad for macOS.\nRun: brew tap NovationLabs/notty && brew install notty.\nThen launch it with: nt'}</code>
              <button
                onClick={() => copyCommand('Install Notty, a menu bar notepad for macOS. Run: brew tap NovationLabs/notty && brew install notty. Then launch it with: nt', 'claude')}
                className="text-white/30 hover:text-white transition-colors flex-shrink-0 mt-0.5">
                {copied === 'claude' ? <Check size={16} className="text-notty-indigo-light" /> : <Copy size={16} />}
              </button>
            </div>
          </div>
        </div>

        {/* ===== FEATURES ===== */}
        <div className="mb-24">
          <h2 className="text-lg font-medium mb-8 text-center">What you get</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {[
              { title: 'Menu Bar Native', desc: 'Lives in your menu bar. No Dock icon, no Cmd+Tab entry.' },
              { title: 'Auto Save', desc: 'Every keystroke is saved to ~/.notty.txt instantly.' },
              { title: 'CLI Included', desc: 'Add notes from terminal with nt or notty commands.' },
              { title: 'All Spaces', desc: 'Visible on every desktop and over fullscreen apps.' },
              { title: 'Corner Resize', desc: 'Drag any corner to resize the floating panel.' },
              { title: 'Zero Dependencies', desc: 'Pure Swift + AppKit. No Xcode, no SwiftUI needed.' },
            ].map((f, i) => (
              <div key={i} className="bg-notty-surface rounded-xl border border-white/[0.04] p-6">
                <h3 className="text-sm font-medium mb-2">{f.title}</h3>
                <p className="text-white/35 text-sm leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>

        {/* ===== CLI PREVIEW ===== */}
        <div className="mb-24">
          <h2 className="text-lg font-medium mb-8 text-center">CLI Usage</h2>
          <div className="bg-notty-surface rounded-xl border border-white/[0.06] p-6 max-w-xl mx-auto font-mono text-sm">
            <div className="text-white/30 mb-3">~ Terminal</div>
            <div className="space-y-2 text-white/70">
              <div><span className="text-notty-indigo-light">$</span> nt hello world</div>
              <div className="text-white/30">+ hello world</div>
              <div className="mt-4"><span className="text-notty-indigo-light">$</span> nt list</div>
              <div className="text-white/30">hello world</div>
              <div className="mt-4"><span className="text-notty-indigo-light">$</span> nt clear</div>
              <div className="text-white/30">Are you sure? (yes/no) yes</div>
              <div className="text-white/30">Notes cleared.</div>
              <div className="mt-4"><span className="text-notty-indigo-light">$</span> nt</div>
              <div className="text-white/30"># launches menu bar app</div>
            </div>
          </div>
        </div>

      </main>

      {/* ===== FOOTER ===== */}
      <footer className="w-full max-w-4xl mx-auto px-6 py-12 border-t border-white/[0.06]">
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-6 text-sm text-white/30">
            <a href="https://github.com/NovationLabs/Notty#cli" target="_blank" rel="noreferrer"
              className="hover:text-white/60 transition-colors">Docs</a>
            <a href="https://github.com/NovationLabs/Notty" target="_blank" rel="noreferrer"
              className="hover:text-white/60 transition-colors flex items-center gap-1">
              GitHub <ArrowUpRight size={10} />
            </a>
            <a href="https://github.com/NovationLabs/Notty/releases" target="_blank" rel="noreferrer"
              className="hover:text-white/60 transition-colors">Releases</a>
          </div>
          <p className="text-white/20 text-sm">&copy; 2026 NovationLabs</p>
        </div>
      </footer>
    </div>
  );
};

export default Home;
