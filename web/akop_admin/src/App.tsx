import './App.css'

function App() {
  return (
    <div className="app-container">
      <header className="app-header">
        <h2>AKOP</h2>
        <span>Kurum Yönetim Paneli</span>
      </header>

      <main className="app-content">
        <div className="welcome-card">
          <h1>AKOP Yönetim Paneli</h1>

          <p>
            Akıllı İhbar ve Saha Operasyon Yönetim Platformu
          </p>

          <span className="status-badge">
            Geliştirme ortamı hazır
          </span>
        </div>
      </main>
    </div>
  )
}

export default App