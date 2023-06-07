defmodule HelloWeb.ChunksController do  
  use HelloWeb, :controller
  require Logger
  alias :mnesia, as: Mnesia

  # NEED new controller
  # need application-start spawning of monitor on ocaml/lwt heartbeats service; call to hydrate it for a session w that session's USERS LIST, their IDs/idxes for the session, TOKEN STATE across all users
  # update to invalidate tokens (in order, we cant invalidate a token without implicitly invalidating (or re-invalidating) all prior tokens in the generated access|refresheslist seq for that session)

  channel_t = %{mono: 1, stereo: 2}
  channel_tnum = %{ 1 => :mono, 2 => :stereo }
  voicing_t = %{hard: 1, soft: 2, med: 3, mutes: 4}
  voicing_tnum = %{ 1 => :hard, 2 => :soft, 3 => :med, 4 => :mutes}
  tone_basis_t = %{just_in: 1, even_temp: 2 }
  tone_basis_tnum = %{ 1 => :just_in, 2 => :even_temp}
  notes_evtmp_t = %{ A: 1, B: 2, C: 3, D: 4, E: 5, F: 6, G: 7, As: 8, Ab: 9, Bb: 10, Cs: 11, Db: 12, Ds: 13, Eb: 14, Fs: 15, Gb: 16, Gs: 17 }
  
  notes_evtmp_tnum = %{  1 => :A, 2 => :B, 3 => :C, 4 => :D, 5 => :E, 6 => :F, 7 => :G, 8 => :As, 9 => :Ab, 10 => :Bb, 11 => :Cs, 12 => :Db, 13 => :Ds, 14 => :Eb, 15 => :Fs, 16 => :Gb, 17 => :Gs }
  
  bass_notes = %{C: 1, F: 1, As: 2, Ds: 2}
  
  guitar_notes = %{E: 3, A: 3, D: 4, G: 4, B: 4, E: 5}
  basic_mode_t = %{major: 1, minor: 2}
  basic_mode_tnum = %{1 => :major, 2 => :minor}

  #def serialnt(nt,nm,instx) do
  #   Map.fetch(note_to_int,nt)*(11*(nm-1)) +  if (instx = :bass), do: 0, else: (1+10+33)
  #end

  #def inst_of_serial(ser_int) do
  #  if (ser_int >= 44), do: :guitar, else: :bass    
  #end
  #def note_of_serial_and_oct(ser_int, oct) do
  #  note_of_int = %{ 1 => :C, 2 => :D, :E => 3, :F => 4, :Dss => 5, :G => 6, :As => 7, :B => 8, :A => 9, :E2 => 10 }
  # sint2 = if (ser_int >= 44), do: ser_int - 44, else: ser_int
  #  Map.fetch(note_of_int,sint2/(oct+1))
  #end
  
  #(defun serial (nt nm inst)
  #(let ((nt-to-int (case nt (:C 1) (:D 2) (:E 3) (:F 4) (:D# 5) (:G 6) (:A# 7) (:B 8) (:A 9) (:E2 10)))
  #(nm-to-int (* (- nm 1) 11))
  #        (inst-to-int (case inst (:bass 0) (:guitar (+ 1 (+ 10 33))))))        # (+ nt-to-int nm-to-int  inst-to-int)))
  
  def apretamo(conn, params) do
    Mnesia.start()
    Mnesia.create_schema([node])
    #Mnesia.create_table(ClientCount, [attributes: [:id, :count]])    
    Mnesia.create_table(StreamCount, [attributes: [:id, :count]])
    Mnesia.create_table(ClientStreamState, [attributes: [:client_id, :current_au_stereo_stream_id, :current_video_stream_id]])
    Mnesia.create_table(ClientStream, [attributes: [:stream_id, :stream_kind, :srate, :client_id, :start_timestamp, :start_chunknum]])
    Mnesia.create_table(Count, [attributes: [:client_stream_id, :nchunks_ya, :srate, :nframes_ya, :nchunks_checked_out]])
    Mnesia.create_table(ChunkRecord, [attributes: [:chunk_record_id, :client_stream_id, :chunk_num,  :subchunks_timestamps_lista, :srate, :framez_count, :fname_to_mojo, :start_timestamp]])
#    Mnesia.add_table_index(ChunkRecord, :client_stream_id)
    Mnesia.create_table(ChunkRecordsCount, [attributes: [:id, :alloc_idx]])
    Mnesia.create_table(FileRsc, [attributes: [:id, :gsid, :fname, :batchnum]])
#    Mnesia.start()
    json conn, %{}    
  end
  
  def streams_first_chunk_time(conn, %{"streamId" => stream_id} = params) do
    #    {:atomic, [h | _]} = Mnesia.index_read(ChunkRecord, stream_id, :client_stream_id)
    lsta = []
    h = {}
    Mnesia.transaction(
      fn ->
    	{:atomic, lsta} = Mnesia.select(ChunkRecord, [{{ChunkRecord, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6", :"$7", :"$8",},  [{:==, :"$1", stream_id}, {:==, :"$3", 0 }],  [:"$$"]}])
      end)
    [h | _] = lsta
    json conn, %{"carEltInTime" => h}
end
  
  def allchunks_in_stream_after_tstamp(conn,  %{"minTimeStamp" => min_tstamp, "streamId" => stream_id } = params) do
    lsta = [];
    Mnesia.transaction(
      fn ->
	if (min_tstamp <= 0) do
	  {:atomic, lsta} = Mnesia.select(ChunkRecord, [{{ChunkRecord, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6", :"$7", :"$8",},  [{:>, :"$8", min_tstamp}, {:==, :"$1", stream_id}],  [:"$$"]}])
	  Logger.info("resulta from select: #{lsta}")
	else
	  {:atomic, lsta} = Mnesia.select(ChunkRecord, [{{ChunkRecord, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6", :"$7", :"$8",},  [{:==, :"$1", stream_id}],  [:"$$"]}])
	  Logger.info("resulta from select: #{lsta}")
	end
      end
    )
    json conn, %{"all" => lsta}
  end
  
  
  def allstreams(conn,  %{"minTimeStamp" => min_tstamp } = params) do
    lsta = []
    Mnesia.transaction(
      fn ->
	if (min_tstamp >= 0) do
	  lsta = Mnesia.select(ClientStream, [{{ClientStream, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6"},  [{:>, :"$5", min_tstamp}],  [:"$$"]}])
	  Logger.info("resulta from select: #{lsta}")
	else
	  lsta = Mnesia.select(ClientStream, [{{ClientStream, :"$1", :"$2", :"$3", :"$4", :"$5", :"$6"},  [],  [:"$$"]}])
	  Logger.info("resulta from select: #{lsta}")
	end
      end      
    )
    json conn, %{"all" => lsta}
  end
  
  def apretacounts(conn, params) do 
    data_to_write = fn ->
      Mnesia.write({StreamCount, 1, 0})
      Mnesia.write({ChunkRecordsCount, 1, 0})      
      #Mnesia.write({ClientCount, 1, 0})
    end
     Mnesia.transaction(data_to_write)
    json conn, %{}
  end

  def apretauserzerostate(conn, params) do
    data_to_write = fn ->
      Mnesia.write({ClientStreamState, 0, -1, -1})
    end
    Mnesia.transaction(data_to_write) 
    json conn, %{}    
  end
  # STREAM_KIND 1 is AUDIO in STEREO
  # STREAM_KIND 2 is VIDEO
  # STREAM_KIND 3 is AUDIO in MONO

  # client calls POST to new_client_stream_src_connection
  # with his client id (0 for now)
  # stream kind one of above ints_of_enums (ensure not str format in json req)
  # and srate
  # response gives his stream id

  # he will do that across all his applicable stream types on startup-connection to mnesia
  # stores those 2 stream ids in client state
  # stores his current nchunks checked out there per stream
  # stores his n chunks fulfilled per stream
  # stores his n frames total per stream, incremental n frames fulfilled across each fulfilled chunk
  # stores, for his currenet chunk, n frames fulfilled
  
  # stores a list of chunk data (maybe not actual sig bytearrays long term)
  #    ^ s.a. n frames in chunk, endpoint timestamp pair, if video the subchunk-intervals timestamps
  #    ^ fulfilled or not, fname in mnesia if fulfilled
  #
  # he sends mnesia
  # client_id, stream_id, chunk_idx, stream_kind, srate, fmt
  # maybe its a wav sent ya
  # maybe its bins of vids

  # he will predict what MOJO writes as file: "chunk_$streamid_$chunkidx.wav" or .bin
  # he knows nframes etc and will report to MNESIA everything
  # MOJO actually won't need timestamps, they are here

  def new_client_stream_src_connection(conn, %{"clientId" => client_id, "streamKind" => stream_kind, "srate" => srate } = params) do
    n_new = 0
    update_data = fn ->
      [{StreamCount, 1, n}] = Mnesia.read({StreamCount, 1})
      Mnesia.write({ClientStreamState, 0, -1, -1})          
      n_new = n+1
      Mnesia.write({StreamCount, 1, n_new})
      Mnesia.write({ClientStream, n_new, stream_kind, srate, client_id, -1, -1})
      Mnesia.write({Count, n_new, 0, srate, 0, 0})
      if (stream_kind == 4) || (stream_kind == 5) do # AUDIO
	[{ClientStreamState, client_id, _, vid_stream_id}] = Mnesia.read({ClientStreamState, client_id})
	Mnesia.write({ClientStreamState, client_id, n_new, vid_stream_id})
      else
	[{ClientStreamState, client_id, au_stream_id, _}] = Mnesia.read({ClientStreamState, client_id})
	Mnesia.write({ClientStreamState, client_id, au_stream_id, n_new})	
      end      
      # client will request and store 3 of these in his browser session
      # new connection means he has to renew these
    end
    Mnesia.transaction(update_data) 
    json conn, %{"resulta" => n_new}  
  end

  def apreta00(conn, params) do
    {:ok, res} = CouchDBEx.db_exists?("samples/")
    Logger.info("resulta from Couch: #{res}")
    # TRUE finally, *BOOM*
    json conn, %{}
  end    
 
 def newmetarecord(conn, %{"srate" => r, "gsid" => gsidx, "chanz" => chanz, "bitdepth" => bitdepth, "fname" => fname, "batchnum" => batchnum} = params) do
   Logger.info("bitdepth: #{bitdepth}")
   Logger.info("batchnum: #{batchnum}")

    update_data = fn ->
#        [{Count, 1, b, rst, _}] = Mnesia.read({Count, 1})
        Mnesia.write({FileRsc, 1, gsidx, fname, batchnum }) #  [attributes: [:id, :gsid, :fname, :batchnum]])
    end
    Mnesia.transaction(update_data)   
    json conn, %{"resulta" => "ok"}   
 end

 def writepairsfile(conn, %{"nlimit" => nlimit}) do
   Mnesia.transaction(
     fn ->
       #       filersc = Mnesia.select(FileRsc,[])
       filersc =  Mnesia.match_object({FileRsc, :_, :_, :_, :_})
       Logger.info("filerscz  #{filersc}")
       # JOIN into string, delimited somehow
       # write to txt file
     end)   
   json conn, %{"resulta" => "ok"}
 end

 def fulfillvideochunk(conn, %{"streamId" => stream_id, "streamKind" => stream_kind, "numFrames" => numframes, "chunkNum" => chunk_num , "frameTimestamps" => ts_list, "fnameToMojo" => fname_to_mojo, "initTime" => ts0} = params) do
   update_data = fn ->
     [{Count, stream_id, nchunks_ya, srate, nframez_ya, nchunks_checked_out}] = Mnesia.read({Count, stream_id})
     [{ChunkRecordsCount, 1, chunk_rec_alloc_idx}] = Mnesia.read({ChunkRecordsCount, 1})


     if (chunk_num == 0) do
       [{ClientStream, stream_id, sk0, srate, cli_id, _, _}] = Mnesia.read(ClientStream, stream_id)
       Mnesia.write({ClientStream, stream_id, sk0, srate, cli_id, ts0, chunk_rec_alloc_idx+1})
     end     
     
     Mnesia.write({ChunkRecordsCount, 1, chunk_rec_alloc_idx+1})
     Mnesia.write({Count, stream_id, nchunks_ya+1, srate, nframez_ya+numframes, nchunks_checked_out})
     Mnesia.write({ChunkRecord, chunk_rec_alloc_idx+1, stream_id, chunk_num, ts_list, srate, numframes, fname_to_mojo, ts0})    
   end
   Mnesia.transaction(update_data) 
   json conn, %{"resulta" => "ok"}   
 end


 # https://www.youtube.com/watch?v=0uYdiqGSZzk
 def checkoutchunks(conn, %{"nChunksToCheckout" => n_chunkz, "streamId" => stream_id, "streamKind" => stream_kind, "numFramesPerChunk" => num_framez_per_chunk, "atSrate" => at_srate} = params) do
   nchunks_newly_checked_out = 0
   orig_chunk = 0
   update_data = fn ->
     [{Count, stream_id, nchunks_ya, srate, nframez_ya, nchunks_checked_out}] = Mnesia.read({Count, stream_id})
     nchunks_newly_checked_out = nchunks_checked_out + n_chunkz
     orig_chunk = nchunks_checked_out
     Mnesia.write({Count, stream_id, nchunks_ya, srate, nframez_ya, nchunks_newly_checked_out})
   end   
   Mnesia.transaction(update_data)
   json conn, %{"resulta" => "ok", "nchunks_checked_out_total" => nchunks_newly_checked_out, "incremental_n_chunks_checked_out" => n_chunkz, "start_chunk_of_checked_out_slice" => orig_chunk}
 end

 # CHUNK_NUM  should start at 0
 
 def fulfillaudiochunk(conn, %{"streamId" => stream_id, "streamKind" => stream_kind, "numFrames" => numframes, "chunkNum" => chunk_num , "frameTimestamps" => ts_list, "fnameToMojo" => fname_to_mojo} = params) do
   [ts0 | _ ] = ts_list
   update_data = fn ->
     [{Count, stream_id, nchunks_ya, srate, nframez_ya, nchunks_checked_out}] = Mnesia.read({Count, stream_id})
     [{ChunkRecordsCount, 1, chunk_rec_alloc_idx}] = Mnesia.read({ChunkRecordsCount, 1})

     if (chunk_num == 0) do
       [{ClientStream, stream_id, sk0, srate, cli_id, _, _}] = Mnesia.read(ClientStream, stream_id)
       Mnesia.write({ClientStream, stream_id, sk0, srate, cli_id, ts0, chunk_rec_alloc_idx+1})
     end
     
     
     Mnesia.write({ChunkRecordsCount, 1, chunk_rec_alloc_idx+1})
     Mnesia.write({Count, stream_id, nchunks_ya+1, srate, nframez_ya+numframes, nchunks_checked_out})
     Mnesia.write({ChunkRecord, chunk_rec_alloc_idx+1, stream_id, chunk_num, [], srate, numframes, fname_to_mojo, ts0})
   end
   
   Mnesia.transaction(update_data)     
   json conn, %{"resulta" => "ok"}
 end
end
