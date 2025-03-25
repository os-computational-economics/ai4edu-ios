"use client";
import React, { useState, useContext } from "react";
import CardList from "./components/CardList";
import HistoryPanel from "./components/HistoryPanel";
import { Pagination } from "@nextui-org/react";
import { ToastContainer, toast } from "react-toastify";
import { WorkspaceContext } from "@/components/layout/layout";
import {
  getWorkspaceRole,
  checkExpired,
  getCurrentUserID,
} from "@/utils/CookiesUtil";
import { Card, ScrollShadow } from "@nextui-org/react";
import {
  getThreadsList,
  getThreadbyID,
  Thread,
  SingleThreadResponse,
} from "@/api/thread/thread";
import useMount from "@/components/hooks/useMount";

export default function App() {
  const [selectedThreadId, setSelectedThreadId] = useState(null);
  const [threads, setThreads] = useState<Thread[]>([]);
  const [threadDetails, setThreadDetails] =
    useState<SingleThreadResponse | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [total, setTotal] = useState(0); // Total number of threads
  const [creatorId, setCreatorId] = useState("");
  const { currentWorkspace, setCurrentWorkspace } =
    useContext(WorkspaceContext);

  useMount(() => {
    fetchLists(currentPage, pageSize);
  });

  const fetchLists = async (page, pageSize) => {
    const workspace_id =
      currentWorkspace?.id ||
      JSON.parse(localStorage.getItem("workspace")!)?.id;
    await checkExpired();
    const roleList = getWorkspaceRole();

    const params = {
      page,
      page_size: pageSize,
      user_id: roleList[workspace_id] === "teacher" ? -1 : getCurrentUserID(), // Passing -1 in place of all, since user_id must be an int
      workspace_id: workspace_id,
    };

    getThreadsList(params)
      .then((res) => {
        setThreads(res.items);
        setTotal(res.total); // Set the total count for pagination
      })
      .catch((error) => {
        console.error("Error fetching threads:", error);
      });
  };

  const fetchThreadDetails = (threadId) => {
    getThreadbyID({ thread_id: threadId })
      .then((response) => {
        setThreadDetails(response); // Set new thread details
      })
      .catch((error) => {
        console.log(error.response.data.detail);
        toast.error(error.response.data.detail, {
          position: "top-right",
          autoClose: 3000,
          hideProgressBar: false,
          closeOnClick: true,
          pauseOnHover: true,
          progress: undefined,
        });
        // console.error('Error fetching thread details:', error);
      });
  };

  const handlePageChange = (page) => {
    setCurrentPage(page);
    fetchLists(page, pageSize);
  };

  const handleSelectThread = (threadId) => {
    setThreadDetails(null);
    fetchThreadDetails(threadId);
  };

  const totalPages = Math.ceil(total / pageSize);
  const matching_thread = threads.filter(
    (e) => e.thread_id == threadDetails?.thread_id
  )[0];

  return (
    <div className="flex flex-col">
      <div className="m-1 mx-4">
        <h1 className="text-xl font-bold my-1">Chat History</h1>
      </div>
      <div className="flex h-[calc(100vh-85px)] w-98%">
        <ToastContainer />
        <div className="flex w-2/5 flex-col">
          <div className="flex-grow overflow-auto">
            <ScrollShadow size={20} className="w-full h-full">
              <CardList threads={threads} onSelect={handleSelectThread} />
            </ScrollShadow>
          </div>
          <div className="flex flex-shrink-0 flex-col items-center justify-center my-6 z-0">
            {total > 0 && (
              <>
                <Pagination
                  total={totalPages}
                  initialPage={currentPage}
                  onChange={handlePageChange}
                />
                <div className="mt-2 text-small text-default-600">{`Total ${total} thread${
                  total === 1 ? `` : `s`
                }`}</div>
              </>
            )}
          </div>
        </div>
        <Card className="flex w-3/5 flex-col items-center justify-center border p-2 mx-3 mb-6 mt-3 dark:border-gray-500">
          {threadDetails ? (
            <HistoryPanel
              thread={matching_thread ? matching_thread : threads[0]}
              threadDetails={threadDetails}
            />
          ) : (
            <div className="text-black-500 text-lg font-semibold">
              Please select a thread to view its details.
            </div>
          )}
        </Card>
      </div>
    </div>
  );
}
