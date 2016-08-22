require 'lib/jcl'

describe Jcl::Job, "Jcl module" do
  it "case 1" do
    job = Jcl::Job.new(1,'hoge')
    expect(job.name).to eq("hoge")
    expect(job.param).to be_empty
    expect(job.command).to eq('JOB')
  end
  it "case 2" do
    job = Jcl::Job.new(1,'hoge','ruby=fun')
    expect(job.name).to eq('hoge')
    expect(job.param).to eq({'ruby'=>'fun'})
    expect(job.to_jcl).to eq("//hoge JOB ruby=fun")
  end
  it "case 3" do
    job = Jcl::Job.new(1, 'hoge', 'ruby=fun')
    job.add_param('perl=good')
    expect(job.param).to eq({'ruby'=>'fun','perl'=>'good'})
    expect(job.to_jcl).to eq("//hoge JOB ruby=fun,perl=good")
  end

  it "should add some step(s)" do
    job = Jcl::Job.new(1, 'hoge', 'ruby=fun')
    s1 = Jcl::Step.new(1, 'fuga')
    job.add_step s1
    expect(job.steps[0]).to eq(s1)
    expect(job.steps[1]).to be_nil
  end

  it "should not append some DD to step" do
    job = Jcl::Job.new(1, 'hoge', 'ruby=fun')
    d1 = Jcl::Dd.new(1, 'fuga')
    expect{ job.add_step(d1) }.to raise_error(RuntimeError)
  end
end
describe Jcl::Step, "that created without Job" do
  it "should have name" do
    step = Jcl::Step.new(1, 'foo')
    expect(step.name).to eq('foo')
    expect(step.param).to be_empty
    expect(step.command).to eq('EXEC')
  end
  it "should have params when given some param-set" do
    step = Jcl::Step.new(1, 'foo','ruby=fun')
    expect(step.name).to eq('foo')
    expect(step.param).to eq({'ruby'=>'fun'})
  end
end
describe Jcl::Dd, "that created without Job or Step" do
  it "should have name" do
    dd = Jcl::Dd.new(1, 'bar')
    expect(dd.name).to eq('bar')
    expect(dd.param).to be_empty
    expect(dd.command).to eq('DD')
  end
end
