import React from 'react';

const ProductCard = ({ product }) => {
  const [green, setGreen] = React.useState(false);
  return (
    <div className="bg-white border p-4 m-4 rounded shadow-md text-center flex items-center flex-col">
      <img src={product.image} alt={product.name} className="h-15 w-15" />
      <h3 className="text-lg font-semibold my-2">{product.name}</h3>
      <p className="text-gray-600">${product.price}</p>
      <button
        className={`${green ? 'bg-green-500' : 'bg-blue-500'} hover:bg-blue-600 text-white font-semibold py-2 px-4 rounded mt-2`}
        onClick={() => {
          fetch(`/buy?id=${product.id}`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
          })
            .then(data => {
              setGreen(true);
              setTimeout(() => {
                setGreen(false);
              }, 500);
            })
            .catch(err => console.log(err));
        }
        }
      >
        Buy
      </button>
    </div>
  );
};

export default ProductCard;