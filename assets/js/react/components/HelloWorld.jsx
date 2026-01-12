import React from 'react';

const HelloWorld = () => {
  return (
    <div className="flex items-center justify-center min-h-[400px]">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-blue-600 mb-4">
          Hello World
        </h1>
        <p className="text-xl text-gray-600">
          This is a React component rendered from a SSR Phoenix page!
        </p>
      </div>
    </div>
  );
};

export default HelloWorld;
