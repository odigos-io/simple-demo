import React, { useEffect, useState } from 'react'

const Header = () => {
  const [data, setData] = useState(null)
  const [isLoading, setLoading] = useState(true)
  useEffect(() => {
    fetch('/rate/usd-eur')
      .then((res) => res.json())
      .then((data) => {
        setData(data)
        setLoading(false)
      })
      .catch((error) => {
        console.error('Error fetching currency data:', error)
        setLoading(false)
      })
  }, [])

  return (
    <div className='bg-blue-300 min-w-screen h-50 flex justify-between items-center py-4'>
      <h1 className='px-5 text-2xl font-semibold text-gray-800'>Keyval Shop</h1>
      <span className='px-5 font-semibold text-gray-800'>1 USD 🇺🇸 = {isLoading ? '...' : JSON.stringify(data)} EUR 🇪🇺</span>
    </div>
  )
}

export default Header
