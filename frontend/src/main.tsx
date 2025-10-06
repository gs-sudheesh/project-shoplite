import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter as Router, Link, Routes, Route } from 'react-router-dom'
import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap/dist/js/bootstrap.bundle.min.js'
// Frontend tracing removed - backend distributed tracing provides all necessary observability
// import './index.css'
import App from './App.tsx'
import CreateProduct from './create-product/CreateProduct.tsx'
import ProductList from './product-list/ProductList.tsx'
import CreateOrder from './create-order/CreateOrder.tsx'
import { Auth0Provider, useAuth0 } from '@auth0/auth0-react'

const domain = import.meta.env.VITE_AUTH0_DOMAIN as string
const clientId = import.meta.env.VITE_AUTH0_CLIENT_ID as string
const audience = import.meta.env.VITE_AUTH0_AUDIENCE as string

// Auth0 configuration loaded

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Auth0Provider domain={domain} clientId={clientId} authorizationParams={{ audience, redirect_uri: window.location.origin, scope: 'openid profile email products:read products:write orders:write' }}>
    <Router>
      <div>
        <nav className="navbar navbar-expand-lg navbar-dark bg-primary shadow-sm">
          <div className="container-fluid">
            <Link to="/" className="navbar-brand fw-bold">
              🛍️ ShopLite
            </Link>
            <button 
              className="navbar-toggler" 
              type="button" 
              data-bs-toggle="collapse" 
              data-bs-target="#navbarNav"
              aria-controls="navbarNav" 
              aria-expanded="false" 
              aria-label="Toggle navigation"
            >
              <span className="navbar-toggler-icon"></span>
            </button>
            <div className="collapse navbar-collapse" id="navbarNav">
              <div className="navbar-nav ms-auto">
                <Link to="/" className="nav-link">
                  🏠 Home
                </Link>
                <Link to="/create-product" className="nav-link">
                  ➕ Create Product
                </Link>
                <Link to="/product-list" className="nav-link">
                  📋 Product List
                </Link>
                <Link to="/create-order" className="nav-link">
                  🛒 Purchase
                </Link>
              </div>
              <AuthButtons />
            </div>
          </div>
        </nav>
        <AuthGate>
          <main className="container-fluid py-4">
            <Routes>
              <Route path="/" element={<App />} />
              <Route path="/create-product" element={<CreateProduct />} />
              <Route path="/product-list" element={<ProductList />} />
              <Route path="/create-order" element={<CreateOrder />} />
            </Routes>
          </main>
        </AuthGate>
      </div>
    </Router>
    </Auth0Provider>
  </StrictMode>,
)

function AuthButtons() {
  const { isAuthenticated, loginWithRedirect, logout, isLoading, user } = useAuth0()
  if (isLoading) return null
  return (
    <div className="d-flex align-items-center ms-3">
      {isAuthenticated ? (
        <>
          <span className="text-white me-3 small">{user?.name || user?.email}</span>
          <button className="btn btn-outline-light" onClick={() => logout({ logoutParams: { returnTo: window.location.origin } })}>Logout</button>
        </>
      ) : (
        <button className="btn btn-outline-light" onClick={() => loginWithRedirect()}>Login</button>
      )}
    </div>
  )
}

function AuthGate({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, loginWithRedirect } = useAuth0()

  if (isLoading) return null

  if (!isAuthenticated) {
    loginWithRedirect({ appState: { returnTo: window.location.pathname } })
    return null
  }

  return <>{children}</>
}
