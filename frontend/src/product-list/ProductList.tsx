import {useState, useEffect } from 'react';
import { useAuth0 } from '@auth0/auth0-react';

type Product = { id: string; name: string; stock: number }

export default function ProductList() {
    const [products, setProducts] = useState<Product[]>([])
    const { getAccessTokenSilently } = useAuth0()

    useEffect(() => {
        (async () => {
            const token = await getAccessTokenSilently({ 
              authorizationParams: { 
                audience: import.meta.env.VITE_AUTH0_AUDIENCE,
                scope: 'products:read'
              } 
            })
            const res = await fetch('http://localhost:8080/api/products', { headers: { Authorization: `Bearer ${token}` } })
            const data = await res.json()
            setProducts(data)
        })()
    }, [getAccessTokenSilently])

    return (
        <div className="row justify-content-center">
            <div className="col-12 col-sm-11 col-md-10 col-lg-8 col-xl-7">
                    <div className="card shadow-sm">
                        <div className="card-header">
                            <h2 className="card-title text-center mb-0">Product Inventory</h2>
                        </div>
                        <div className="card-body p-0">
                            {products.length > 0 ? (
                                <div className="table-responsive">
                                    <table className="table table-striped table-hover mb-0">
                                        <thead className="table-dark">
                                            <tr>
                                                <th scope="col" className="px-4">Product ID</th>
                                                <th scope="col">Product Name</th>
                                                <th scope="col" className="text-center">Stock</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {products.map(product => (
                                                <tr key={product.id}>
                                                    <td className="px-4 font-monospace text-muted small">
                                                        {product.id.substring(0, 8)}...
                                                    </td>
                                                    <td className="fw-medium">{product.name}</td>
                                                    <td className="text-center">
                                                        <span className={`badge rounded-pill ${product.stock > 10 ? 'bg-success' : product.stock > 0 ? 'bg-warning' : 'bg-danger'}`}>
                                                            {product.stock}
                                                        </span>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            ) : (
                                <div className="text-center py-5">
                                    <div className="text-muted">
                                        <i className="bi bi-box-seam fs-1 mb-3 d-block"></i>
                                        <h4>No Products Available</h4>
                                        <p>Start by creating your first product!</p>
                                    </div>
                                </div>
                            )}
                        </div>
                        {products.length > 0 && (
                            <div className="card-footer text-muted text-center">
                                <small>Total Products: {products.length}</small>
                            </div>
                        )}
                    </div>
                </div>
            </div>
    )
}
