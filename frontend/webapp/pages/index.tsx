import { useState, useEffect } from 'react'
import { Inter } from 'next/font/google'
import ProductCard from '../components/ProductCard'
import Header from '../components/Header'

const inter = Inter({ subsets: ['latin'] })

type Product = {
  id: number
  name: string
  price: number
  image: string
}

export default function Home() {
  // fetch products
  const [data, setData] =  useState<Product[]>([])
  const [isLoading, setLoading] = useState(true)
  useEffect(() => {
    fetch('/products')
      .then((res) => res.json())
      .then((data) => {
        setData(data)
        setLoading(false)
      })
  }, [])
 
  if (isLoading) return <p>Loading...</p>
  if (!data) return <p>No products data</p>

  return (
    <main
      className={` ${inter.className}`}
    >
      <Header />
      <div className="bg-gray-100 h-full grid grid-cols-6">
      {data.map((product: any) => (
        <ProductCard key={product.id} product={product} />)
      )}
      </div>
    </main>
  )
}
