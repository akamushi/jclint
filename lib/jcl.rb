require 'ext/string'

module Jcl
  
  CHARSET_NAME    = '[A-Z0-9@#.]+'
  IDENT_JOB       = %r|^//(#{CHARSET_NAME})\s+JOB\s+(\S+)\s*$|
  IDENT_EXEC      = %r|^//(#{CHARSET_NAME})\s+EXEC\s+(\S+)\s*$|
  IDENT_DD        = %r[^(//|&/)(#{CHARSET_NAME}+)\s+DD\s+(\S+)\s*$]
  IDENT_CONCAT    = %r|^//\s+DD\s+(\S+)\s*$|
  IDENT_PARAM     = %r|^//\s+(\S+)\s*$|
  IDENT_COMMENT   = %r|^//\*|
  IDENT_PERTITION = %r|^/\*|
  IDENT_ENDJCL    = %r|^//$|

  def self.load_file filename
    current_job =  current_step  = current_dd = nil

    File.open(filename)do |file|
      file.each_with_index do |line, idx|
        line = (line.chomp)[0..71]

        case
        when line =~ IDENT_JOB
          #puts idx.to_s + ':ident_job:' + $1 + ',' + $2
          current_job  = Job.new idx, $1, $2
          current_step = nil
          current_dd   = nil
          current_data = nil

        when line =~ IDENT_EXEC
          #puts idx.to_s + ':ident_exec:' + $1 + ',' + $2
          current_step = Step.new idx, $1, $2
          current_job.add_step(current_step)
          current_dd   = nil

        when line =~ IDENT_DD
          #puts idx.to_s + ':ident_dd:' + $2 + ',' + $3
          current_data = Dd.new idx, $2, $3 if $1 == '//'
          current_data = ManagedDd.new idx, $2, $3 if $1 == '&/'
          current_dd = current_data
          if current_step
            current_step.add_dd(current_dd)
          else
            current_job.add_lib(current_dd)
          end

        when line =~ IDENT_CONCAT
          #puts idx.to_s + ':ident_concat:' + $1
          if current_step
            concat_data = Dd.new idx, current_dd.name, $1
            current_step.add_dd(concat_data)
          end

        when line =~ IDENT_PARAM
          #puts idx.to_s + ':ident_param:' + $1
          case
          when current_dd   then current_dd.add_param $1
          when current_step then current_step.add_param $1
          when current_job  then current_job.add_param  $1
          end

        when line =~ IDENT_COMMENT
          #puts idx.to_s + ':ident_comment:'

        when line =~ IDENT_PERTITION
          #puts idx.to_s + ':ident_pertition:'

        when line =~ IDENT_ENDJCL
          #puts idx.to_s + ':ident_endjcl:'

        else
          if current_dd
            current_dd.cardin += line
          end
        end
      end
    end
    current_job
  end

  module JclStatement
    attr_accessor :name, :param
    attr_reader :command, :linenumber

    def initialize linenumber, command, arg
      @command = command
      @name = arg.shift
      param = arg.shift
      @param = param ? param.parametize : {}
      @linenumber = linenumber
    end
    def add_param str
      @param = @param ? @param.update(str.parametize) : str.parametize
    end
    def to_jcl
      "//#{@name} #{@command} #{@param.to_a.sort{|a,b|(b[0]<=>a[0])}.
      map{|pair|"#{pair[0]}=#{pair[1]}"}.join(',')}"
    end
    def is_job?;  self.command == 'JOB'  end
    def is_step?; self.command == 'EXEC' end
    def is_dd?;   self.command == 'DD'   end
  end


  class Job
    include JclStatement
    attr_accessor :libs,:steps
    def initialize idx, *arg
      super idx, 'JOB', arg
      @libs  = []
      @steps = []
    end
    def add_lib lib
      if lib.is_dd?
        @libs.push lib
      else
        raise "JOBLIB append error: #{lib.inspect} is not DD."
      end
    end
    def add_step step
      if step.is_step?
        @steps.push step
      else
        raise
      end
    end
  end



  class Step
    include JclStatement
    attr_accessor :libs,:dds
    def initialize idx, *arg
      super idx, 'EXEC', arg
      @libs = []
      @dds = []
    end
    def add_lib lib
      if lib.is_dd?
        @libs.push lib
      else
        raise
      end
    end
    def add_dd  dd
      if dd.is_dd?
        @dds.push dd
      else
        raise
      end
    end
  end



  class Dd
    include JclStatement
    attr_accessor :cardin
    def initialize idx, *arg
      super idx, 'DD', arg
      @cardin = ''
    end
    def dsn
      @param['DSN']
    end
    def dsn=(str)
      @param['DSN'] = str
    end
  end
  
  class ManagedDd < Dd
  end
  
end
