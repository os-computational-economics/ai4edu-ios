'use client'

import React from 'react'
import { Card, CardHeader, CardFooter, Chip } from '@nextui-org/react'

const ThreadCard = ({ thread, onSelect }) => (
  <Card isPressable onPress={() => onSelect(thread.thread_id)}>
    <CardHeader className="justify-between mb-0 pb-0">
      <div className="flex gap-1">
        <h2 className="text-medium font-bold text-default-700">{thread.agent_name}</h2>
      </div>
    </CardHeader>
    <CardFooter>
      <div className="flex justify-between w-full">
      <Chip size='sm' className='rounded-lg'>{thread.workspace_id}</Chip>
        <p className="text-small font-semibold text-default-600">
          {new Date(`${thread.created_at}Z`).toLocaleString()}
        </p>
        {/* <p className="text-small font-semibold text-default-600">{thread.student_id}</p> */}
      </div>
    </CardFooter>
  </Card>
)

const CardList = ({ threads, onSelect }) => (
  <div className="grid grid-cols-1 gap-4 p-3">
    {threads.map((thread) => (
      <ThreadCard key={thread.thread_id} thread={thread} onSelect={onSelect} />
    ))}
  </div>
)

export default CardList
