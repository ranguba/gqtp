# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

module GQTP
  class Header
    # struct _grn_com_header {
    #   uint8_t proto;
    #   uint8_t qtype;
    #   uint16_t keylen;
    #   uint8_t level;
    #   uint8_t flags;
    #   uint16_t status;
    #   uint32_t size;
    #   uint32_t opaque;
    #   uint64_t cas;
    # };

    class << self
      def parse(chunk)
        return nil if chunk.bytesize < size
        header = new
        header.proto, header.query_type, header.key_length,
          header.level, header.flags, header.status, header.size,
          header.opaque, cas_high, cas_low = chunk.unpack(pack_format)
        header.cas = cas_high << 32 + cas_low
        header
      end

      def size
        24
      end

      def pack_format
        "CCnCCnNNNN"
      end
    end

    attr_accessor :proto, :query_type, :key_length, :level, :flags
    attr_accessor :status, :size, :opaque, :cas
    def initialize
      @proto = Protocol::GQTP
      @query_type = ContentType::NONE
      @key_length = 0
      @level = 0
      @flags = 0
      @status = Status::SUCCESS
      @size = 0
      @opaque = 0
      @cas = 0
    end

    def pack
      data = [
        @proto, @query_type, @key_length, @level,
        @flags, @status, @size, @opaque, @cas >> 32, @cas & (2 ** 32),
      ]
      data.pack(self.class.pack_format)
    end

    module Protocol
      GQTP = 0xc7
    end

    module ContentType
      NONE    = 0
      TSV     = 1
      JSON    = 2
      XML     = 3
      MSGPACK = 4
    end

    module Flag
      MORE  = 0x01
      TAIL  = 0x02
      HEAD  = 0x04
      QUIET = 0x08
      QUIT  = 0x10
    end

    module Status
      SUCCESS                             = 0
      END_OF_DATA                         = 1
      UNKNOWN_ERROR                       = 65535
      OPERATION_NOT_PERMITTED             = 65534
      NO_SUCH_FILE_OR_DIRECTORY           = 65533
      NO_SUCH_PROCESS                     = 65532
      INTERRUPTED_FUNCTION_CALL           = 65531
      INPUT_OUTPUT_ERROR                  = 65530
      NO_SUCH_DEVICE_OR_ADDRESS           = 65529
      ARG_LIST_TOO_LONG                   = 65528
      EXEC_FORMAT_ERROR                   = 65527
      BAD_FILE_DESCRIPTOR                 = 65526
      NO_CHILD_PROCESSES                  = 65525
      RESOURCE_TEMPORARILY_UNAVAILABLE    = 65524
      NOT_ENOUGH_SPACE                    = 65523
      PERMISSION_DENIED                   = 65522
      BAD_ADDRESS                         = 65521
      RESOURCE_BUSY                       = 65520
      FILE_EXISTS                         = 65519
      IMPROPER_LINK                       = 65518
      NO_SUCH_DEVICE                      = 65517
      NOT_A_DIRECTORY                     = 65516
      IS_A_DIRECTORY                      = 65515
      INVALID_ARGUMENT                    = 65514
      TOO_MANY_OPEN_FILES_IN_SYSTEM       = 65513
      TOO_MANY_OPEN_FILES                 = 65512
      INAPPROPRIATE_I_O_CONTROL_OPERATION = 65511
      FILE_TOO_LARGE                      = 65510
      NO_SPACE_LEFT_ON_DEVICE             = 65509
      INVALID_SEEK                        = 65508
      READ_ONLY_FILE_SYSTEM               = 65507
      TOO_MANY_LINKS                      = 65506
      BROKEN_PIPE                         = 65505
      DOMAIN_ERROR                        = 65504
      RESULT_TOO_LARGE                    = 65503
      RESOURCE_DEADLOCK_AVOIDED           = 65502
      NO_MEMORY_AVAILABLE                 = 65501
      FILENAME_TOO_LONG                   = 65500
      NO_LOCKS_AVAILABLE                  = 65499
      FUNCTION_NOT_IMPLEMENTED            = 65498
      DIRECTORY_NOT_EMPTY                 = 65497
      ILLEGAL_BYTE_SEQUENCE               = 65496
      SOCKET_NOT_INITIALIZED              = 65495
      OPERATION_WOULD_BLOCK               = 65494
      ADDRESS_IS_NOT_AVAILABLE            = 65493
      NETWORK_IS_DOWN                     = 65492
      NO_BUFFER                           = 65491
      SOCKET_IS_ALREADY_CONNECTED         = 65490
      SOCKET_IS_NOT_CONNECTED             = 65489
      SOCKET_IS_ALREADY_SHUTDOWNED        = 65488
      OPERATION_TIMEOUT                   = 65487
      CONNECTION_REFUSED                  = 65486
      RANGE_ERROR                         = 65485
      TOKENIZER_ERROR                     = 65484
      FILE_CORRUPT                        = 65483
      INVALID_FORMAT                      = 65482
      OBJECT_CORRUPT                      = 65481
      TOO_MANY_SYMBOLIC_LINKS             = 65480
      NOT_SOCKET                          = 65479
      OPERATION_NOT_SUPPORTED             = 65478
      ADDRESS_IS_IN_USE                   = 65477
      ZLIB_ERROR                          = 65476
      LZO_ERROR                           = 65475
      STACK_OVER_FLOW                     = 65474
      SYNTAX_ERROR                        = 65473
      RETRY_MAX                           = 65472
      INCOMPATIBLE_FILE_FORMAT            = 65471
      UPDATE_NOT_ALLOWED                  = 65470
      TOO_SMALL_OFFSET                    = 65469
      TOO_LARGE_OFFSET                    = 65468
      TOO_SMALL_LIMIT                     = 65467
      CAS_ERROR                           = 65466
      UNSUPPORTED_COMMAND_VERSION         = 65465
    end
  end
end
