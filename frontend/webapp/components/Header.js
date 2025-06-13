import React, { useEffect, useState } from 'react'

const Header = () => {
  const [isLoading, setLoading] = useState(true)
  const [convertedCurrency, setConvertedCurrency] = useState(null)

  useEffect(() => {
    fetch('/rate/usd-eur')
      .then((res) => res.text())
      .then((data) => {
        setConvertedCurrency(data)
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
      <span className='px-5 font-semibold text-gray-800'>{isLoading ? 'Loading...' : convertedCurrency}</span>
    </div>
  )
}

export default Header
