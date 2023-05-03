import { useState } from 'react'
import {
  AppConfig,
  UserSession,
  AuthDetails,
  showConnect
} from '@stacks/connect';

import {
  StacksMocknet
} from '@stacks/network';

import {
  stringUtf8CV
} from '@stacks/transactions';

function App() {

  const [message , setMessage] = useState("");
  const [transactionId , setTransactionId] = useState("");
  const [currentMessage , setCurrentMessage] = useState("");

  const connectWallet = () => {

  };

  const handleMessage = e => {

  };

  return (
    <div className='flex justify-center items-center h-screen'>
      <h1 className='text-3xl'>
        Hello Stacks
      </h1>
    </div>
  )
}

export default App
