import { useState } from 'react';
import { useAuth0 } from '@auth0/auth0-react';

export default function CreateProduct() {
  const [name, setName] = useState('');
  const [stock, setStock] = useState(0);
  const [msg, setMsg] = useState<string>('');
  const { getAccessTokenSilently } = useAuth0();

  const createProduct = async () => {
    try {
      console.log('Getting token...');
      const token = await getAccessTokenSilently({ 
        authorizationParams: { 
          audience: import.meta.env.VITE_AUTH0_AUDIENCE,
          scope: 'products:write'
        } 
      });
      console.log('Token received, making API call...');
      const res = await fetch('http://localhost:8080/api/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ name, stock }),
      });
      console.log('API response:', res.status);
      const data = await res.json();
      setMsg(JSON.stringify(data));
      setName('');
      setStock(0);
    } catch (error) {
      console.error('Error creating product:', error);
      setMsg(`Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  return (
    <div className="row justify-content-center">
      <div className="col-12 col-sm-10 col-md-8 col-lg-6 col-xl-5">
        <div className="card shadow-sm">
          <div className="card-body p-4">
            <h2 className="card-title text-center mb-4">Create Product</h2>
            <form>
              <div className="mb-3">
                <label htmlFor="productName" className="form-label">Product Name</label>
                <input
                  id="productName"
                  type="text"
                  className="form-control form-control-lg"
                  placeholder="Enter product name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                />
              </div>
              <div className="mb-4">
                <label htmlFor="initialStock" className="form-label">Initial Stock</label>
                <input
                  id="initialStock"
                  type="number"
                  className="form-control form-control-lg"
                  placeholder="Enter initial stock quantity"
                  value={stock}
                  min={0}
                  onChange={(e) => setStock(parseInt(e.target.value || '0'))}
                />
              </div>
              <div className="d-grid">
                <button 
                  type="button"
                  className="btn btn-primary btn-lg" 
                  onClick={createProduct} 
                  disabled={!name || stock < 0}
                >
                  Create Product
                </button>
              </div>
            </form>

            {msg && (
              <div className="mt-4">
                <div className="alert alert-info">
                  <pre className="mb-0">{msg}</pre>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
