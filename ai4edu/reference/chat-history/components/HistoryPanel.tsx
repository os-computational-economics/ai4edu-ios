import React from "react";
import { Button } from "@nextui-org/react";
import { CSVLink } from "react-csv";
import ReactMarkdown from "react-markdown";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import rehypeHighlight from "rehype-highlight";
import "katex/dist/katex.min.css"; // CSS for LaTeX rendering
import "highlight.js/styles/atom-one-dark.min.css"; // CSS for code highlighting
import { preprocessLaTeX } from "@/utils/CustomMessageRender";
import Link from "next/link";
import { Thread } from "@/api/thread/thread";
import { getCurrentUserID } from "@/utils/CookiesUtil";
import { Bot, User } from "lucide-react";

// Define a type for individual messages
type Message = {
  thread_id: string;
  created_at: string;
  msg_id: string;
  user_id: string;
  role: string;
  content: string;
};

// Define a type for the grouped messages
type GroupedMessages = {
  [key: string]: {
    userId: string;
    messages: Message[];
  };
};

// Define props for the HistoryPanel component
type HistoryPanelProps = {
  thread: Thread;
  threadDetails: {
    messages: Message[];
  };
};

const HistoryPanel: React.FC<HistoryPanelProps> = ({
  thread,
  threadDetails,
}) => {
  console.log("Received thread details in HistoryPanel:", threadDetails);
  const currentUserId = getCurrentUserID();

  // Group messages by user_id
  const groupedMessages = threadDetails.messages.reduce<GroupedMessages>(
    (acc, message) => {
      if (!acc[message.user_id]) {
        acc[message.user_id] = {
          userId: message.user_id,
          messages: [],
        };
      }
      acc[message.user_id].messages.push(message);
      return acc;
    },
    {}
  );
  return (
    <div className="h-full w-full overflow-y-scroll">
      {Object.values(groupedMessages).map((group, index) => (
        <div key={index} className="mb-4 relative">
          <div className="sticky bg-gray-50 backdrop-blur-md bg-opacity-50 dark:bg-black dark:backdrop-blur-md dark:bg-opacity-50 rounded-xl top-0 z-10 flex lg:flex-row flex-col items-center justify-between border dark:border-gray-500 pb-2 px-4 pt-2 text-left">
            {/* <h3 className="text-lg font-semibold">Current Student: {group.userId}</h3> */}
            <h3 className="text-lg font-semibold">Student Chat</h3>
            <div className="inline-flex sm:flex-row flex-col items-center gap-1">
              <CSVLink
                data={group.messages.map(
                  ({ thread_id, created_at, msg_id, role, content }) => ({
                    ThreadID: thread_id,
                    CreatedAt: created_at,
                    MessageID: msg_id,
                    // UserID: user_id,
                    Role: role,
                    Content: content,
                  })
                )}
                filename={`${group.messages[0].thread_id.slice(
                  0,
                  8
                )}_chat_log.csv`}
                target="_blank"
              >
                <Button color="primary" variant="flat">
                  Download Record
                </Button>
              </CSVLink>
              {String(currentUserId) === String(group.userId) && (
                <div>
                  <Link
                    href={`/agents/${thread.agent_id}/${group.messages[0].thread_id}?from=chat-history`}
                  >
                    <Button color="primary" variant="flat" className="ml-2">
                      Continue Chat
                    </Button>
                  </Link>
                </div>
              )}
            </div>
          </div>
          {group.messages.map((message, idx) => (
            <div
              key={idx}
              className={`m-2 p-2 ${
                message.role === "human" ? "text-right" : "text-left"
              }`}
            >
              <div
                className={`inline-block max-w-[90%] rounded-lg p-2 ${
                  message.role === "human"
                    ? "bg-slate-200 dark:bg-black dark:text-white"
                    : "bg-orange-50 dark:bg-slate-800 dark:text-white"
                }`}
                style={{ boxShadow: "0 2px 4px rgba(0,0,0,0.1)" }}
              >
                {/* Icon rendering based on role */}
                {message.role === "human" ? (
                  <User className="mr-2 inline-block text-green-600" />
                ) : (
                  <Bot className="mr-2 inline-block text-sky-600" />
                )}

                <p className="text-sm text-left overflow-x-auto">
                  <ReactMarkdown
                    remarkPlugins={[remarkMath]}
                    rehypePlugins={[rehypeKatex, rehypeHighlight]}
                  >
                    {preprocessLaTeX(message.content)}
                  </ReactMarkdown>
                  {/* {message.content} */}
                </p>
                <p className="text-xs text-gray-600">
                  {new Date(parseInt(message.created_at)).toLocaleString()}
                </p>
              </div>
            </div>
          ))}
        </div>
      ))}
    </div>
  );
};

export default HistoryPanel;
