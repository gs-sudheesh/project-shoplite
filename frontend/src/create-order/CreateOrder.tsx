import { useEffect, useState } from 'react'
import { useAuth0 } from '@auth0/auth0-react'

type Product = { id: string; name: string; stock: number }

export default function CreateOrder() {
  const [products, setProducts] = useState<Product[]>([])
  const [selected, setSelected] = useState<string>("")
  const [qty, setQty] = useState(1)
  const [msg, setMsg] = useState<string>("")
  const { getAccessTokenSilently } = useAuth0()

  useEffect(() => {
    (async () => {
      const token = await getAccessTokenSilently({ 
        authorizationParams: { 
          audience: import.meta.env.VITE_AUTH0_AUDIENCE,
          scope: 'products:read'
        } 
      })
      const response = await fetch('http://localhost:8080/api/products', { headers: { Authorization: `Bearer ${token}` } })
      const data = await response.json()
      setProducts(data)
    })()
  }, [getAccessTokenSilently])

      const placeOrder = async () => {
      const token = await getAccessTokenSilently({ 
        authorizationParams: { 
          audience: import.meta.env.VITE_AUTH0_AUDIENCE,
          scope: 'orders:write'
        } 
      })
      const response = await fetch('http://localhost:8080/api/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ productId: selected, quantity: qty })
      })
      const data = await response.json()
      setMsg(JSON.stringify(data))
      // refresh list
      const updated = await fetch('http://localhost:8080/api/products', { headers: { Authorization: `Bearer ${token}` } }).then(updatedProductResponse => updatedProductResponse.json())
      setProducts(updated)
    }

  return (
    <div className="row justify-content-center">
      <div className="col-12 col-sm-11 col-md-10 col-lg-8 col-xl-7">
          <div className="text-center mb-4">
            <h1 className="display-5 mb-3">Purchase Product</h1>
          </div>
          
          {/* Available Products Section */}
          <div className="card mb-4">
            <div className="card-header">
              <h3 className="card-title mb-0">Available Products</h3>
            </div>
            <div className="card-body">
              {products.length > 0 ? (
                <div className="list-group list-group-flush">
                  {products.map(product => (
                    <div key={product.id} className="list-group-item d-flex justify-content-between align-items-center px-0">
                      <span className="fw-medium">{product.name}</span>
                      <span className="badge bg-primary rounded-pill">Stock: {product.stock}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center text-muted">
                  <p>No products available</p>
                </div>
              )}
            </div>
          </div>

          {/* Place Order Section */}
          <div className="card">
            <div className="card-header">
              <h3 className="card-title mb-0">Place Order</h3>
            </div>
            <div className="card-body">
              <form>
                <div className="mb-3">
                  <label htmlFor="productSelect" className="form-label">Select Product</label>
                  <select 
                    id="productSelect"
                    className="form-select form-select-lg" 
                    value={selected} 
                    onChange={event => setSelected(event.target.value)}
                  >
                    <option value="">Choose a product...</option>
                    {products.map(product => (
                      <option key={product.id} value={product.id}>
                        {product.name} (Stock: {product.stock})
                      </option>
                    ))}
                  </select>
                </div>
                <div className="mb-4">
                  <label htmlFor="quantity" className="form-label">Quantity</label>
                  <input 
                    id="quantity"
                    type="number" 
                    className="form-control form-control-lg" 
                    value={qty} 
                    min={1} 
                    placeholder="Enter quantity"
                    onChange={event => setQty(parseInt(event.target.value||"1"))} 
                  />
                </div>
                <div className="d-grid">
                  <button 
                    type="button"
                    className="btn btn-success btn-lg" 
                    onClick={placeOrder} 
                    disabled={!selected || qty<1}
                  >
                    Place Order
                  </button>
                </div>
              </form>

              {msg && (
                <div className="mt-4">
                  <div className="alert alert-info">
                    <strong>Order Result:</strong>
                    <pre className="mb-0 mt-2">{msg}</pre>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
    </div>
  )
}
