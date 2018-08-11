// Copyright (c) 2014-2018, The Monero Project
// 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice, this list
//    of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// Parts of this file are originally copyright (c) 2012-2013 The Cryptonote developers

#include "chaingen.h"
#include "rct_transfer.h"

using namespace std;

using namespace epee;
using namespace cryptonote;


gen_rct_transfer::gen_rct_transfer()
{
  REGISTER_CALLBACK("check", gen_rct_transfer::check);
}
//-----------------------------------------------------------------------------------------------------
bool gen_rct_transfer::generate(std::vector<test_event_entry> &events) const
{
  uint64_t ts_start = 1338224400;

  GENERATE_ACCOUNT(first_miner_account);
  //                                                                                          events index
  MAKE_GENESIS_BLOCK(events, blk_0, first_miner_account, ts_start);                           //  0
  MAKE_ACCOUNT(events, alice);
  MAKE_NEXT_BLOCK(events, blk_1, blk_0, first_miner_account);                                 //  1
  MAKE_NEXT_BLOCK(events, blk_2, blk_1, first_miner_account);                                 //  2
  MAKE_NEXT_BLOCK(events, blk_3, blk_2, first_miner_account);                                 //  3
  MAKE_NEXT_BLOCK(events, blk_4, blk_3, alice);                                 //  4
  MAKE_NEXT_BLOCK(events, blk_5, blk_4, alice);                                 //  5
  MAKE_NEXT_BLOCK(events, blk_6, blk_5, alice);                                 //  6
  MAKE_NEXT_BLOCK(events, blk_7, blk_6, alice);                                 //  7
  REWIND_BLOCKS_N(events, blk_23r, blk_7, first_miner_account, 100);                                //  30...N1
  MAKE_TX(events, tx_0, alice, alice, MK_COINS(10), blk_23r);                    //  N1+1
  DO_CALLBACK(events, "check");                                                     //  N1+6
  /*
  //check orphaned blocks
  MAKE_NEXT_BLOCK_NO_ADD(events, blk_orph_27, blk_16, get_test_target(), first_miner_account);     
  MAKE_NEXT_BLOCK(events, blk_25, blk_orph_27, get_test_target(), first_miner_account);       //  36
  MAKE_NEXT_BLOCK(events, blk_26, blk_25, get_test_target(), first_miner_account);            //  37
  DO_CALLBACK(events, "check_orphaned_chain_1");                                              //  38
  ADD_BLOCK(events, blk_orph_27);                                                             //  39
  DO_CALLBACK(events, "check_orphaned_switched_to_alternative");                              //  40
  
  //check orphaned check to main chain
  MAKE_NEXT_BLOCK_NO_ADD(events, blk_orph_32, blk_16, get_test_target(), first_miner_account);     
  MAKE_NEXT_BLOCK(events, blk_28, blk_orph_32, get_test_target(), first_miner_account);       //  41
  MAKE_NEXT_BLOCK(events, blk_29, blk_28, get_test_target(), first_miner_account);            //  42
  MAKE_NEXT_BLOCK(events, blk_30, blk_29, get_test_target(), first_miner_account);            //  43
  MAKE_NEXT_BLOCK(events, blk_31, blk_30, get_test_target(), first_miner_account);            //  44
  DO_CALLBACK(events, "check_orphaned_chain_2");                                              //  45
  ADD_BLOCK(events, blk_orph_32);                                                             //  46
  DO_CALLBACK(events, "check_orphaned_switched_to_main");                                     //  47

  //check orphaned check to main chain
  MAKE_NEXT_BLOCK_NO_ADD(events, blk_orph_39, blk_16, get_test_target(), first_miner_account);     
  MAKE_NEXT_BLOCK(events, blk_33, blk_orph_39, get_test_target(), first_miner_account);       //  48
  MAKE_NEXT_BLOCK(events, blk_34, blk_33, get_test_target(), first_miner_account);            //  49
  MAKE_NEXT_BLOCK_NO_ADD(events, blk_orph_41, blk_34, get_test_target(), first_miner_account);     
  MAKE_NEXT_BLOCK(events, blk_35, blk_orph_41, get_test_target(), first_miner_account);       //  50
  MAKE_NEXT_BLOCK(events, blk_36, blk_35, get_test_target(), first_miner_account);            //  51
  MAKE_NEXT_BLOCK_NO_ADD(events, blk_orph_40, blk_36, get_test_target(), first_miner_account);     
  MAKE_NEXT_BLOCK(events, blk_37, blk_orph_40, get_test_target(), first_miner_account);       //  52
  MAKE_NEXT_BLOCK(events, blk_38, blk_37, get_test_target(), first_miner_account);            //  53
  DO_CALLBACK(events, "check_orphaned_chain_38");                                             //  54
  ADD_BLOCK(events, blk_orph_39);                                                             //  55
  DO_CALLBACK(events, "check_orphaned_chain_39");                                             //  56
  ADD_BLOCK(events, blk_orph_40);                                                             //  57
  DO_CALLBACK(events, "check_orphaned_chain_40");                                             //  58
  ADD_BLOCK(events, blk_orph_41);                                                             //  59
  DO_CALLBACK(events, "check_orphaned_chain_41");                                             //  60
  */
  return true;
}
//-----------------------------------------------------------------------------------------------------
bool gen_rct_transfer::check(cryptonote::core& c, size_t ev_index, const std::vector<test_event_entry> &events)
{
  return true;
}
//----------------------------------------------------------------------------------------------------- 
