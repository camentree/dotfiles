const buttonLabels = { open: 'review', requeue: 'to queue' }

const buttonHelp = (name, sectionName) => ({
  answer: "Answer the agent's question. A box opens with the question, its options and a field for your words",
  merge: 'Merge this pull request and delete its remote branch. Asks once more before it merges',
  queue: 'Have it prepared for your review: an agent addresses the comments, fixes CI or puts the review together, and the card lands in Queued when it is ready',
  review: 'Open its review pages in one Safari tab group and move it to In Progress',
  block: 'Block it: say in a line what it is blocked on. It moves to Blocked, the reason goes in its comments, and the assistant is told',
  requeue: 'Move it back to Queued, to review later. No agent is started',
  agent: sectionName === 'Review' ? 'Start an agent on this: it prepares a review of this pull request. A box opens first for an optional note to it'
    : sectionName === 'Address' ? 'Start an agent on this: it works through the review comments on this pull request. A box opens first for an optional note to it'
    : 'Start an agent on this: it fixes this pull request. A box opens first for an optional note to it',
  note: "Send this task's agent a note. A box opens for the message",
  open: sectionName === 'Review' ? 'Tell the agent you are ready to review: it opens difit and the tabs it prepared'
    : 'Tell the agent you are ready to look at its work: it opens the change in difit with what it prepared',
  start: 'Start an agent on this task',
  message: 'Message the assistant about this task',
  comment: 'Leave yourself a comment on this task · not sent to anyone',
  dismiss: 'Hide this card for good. Restore it from the hidden list under the section'
})[name]

const buttonOff = (name, item, sectionName) => {
  if ((item.buttons || []).includes(name)) return name === item.primary && item.waits ? item.waits : ''
  const reviewing = Boolean(item.agent) && item.agent.state === 'reviewing'
  const working = Boolean(item.agent) && item.agent.state === 'working'
  if (name === 'merge') return item.waits || 'it is not approved yet'
  if (name === 'queue' && item.waitsOnTeammate) return "nothing for you to review: it waits on a teammate's review. It turns on once something comes back to you (threads, failing checks, changes requested)"
  if (name === 'queue' && item.state === 'preparing') return 'an agent is preparing it; it lands in Queued when ready'
  if (name === 'queue' && item.state === 'in-progress') return 'you are reviewing it. Press to queue to move it back to Queued'
  if (name === 'queue' && item.state !== 'queued' && (item.materials || []).length) return 'its review is already prepared. Press to queue to move it to Queued'
  if (name === 'queue') return 'it is already in Queued'
  if (name === 'requeue' && item.state === 'queued') return 'it is already in Queued'
  if (name === 'requeue') return 'only a card in progress or blocked moves back to Queued. Press queue to have it prepared'
  if (name === 'review') return 'nothing to review yet: it has no review materials. Press queue to have them prepared'
  if (name === 'block') return 'it is already blocked'
  if (name === 'agent') return 'no agent can be started or reached on this card'
  if (name === 'open' && reviewing) return 'it is already open. Comment in difit: the agent picks up each comment as you post it'
  if (name === 'open' && working) return 'the agent is still preparing it'
  if (name === 'open') return sectionName === 'Review' ? 'no review is prepared yet. Press agent to have one prepared' : 'no fixes are ready yet. Press agent to have the comments addressed'
  if (name === 'start') return 'an agent has already started this'
  return 'not available on this card yet'
}

const buttonTitle = (name, item, sectionName) => {
  const live = name === 'agent' && Boolean(item.agent) && !['done', 'stopped'].includes(item.agent.state)
  if (name === 'open' && item.agent && item.agent.state === 'reviewing') return 'It is open in difit: opens it in a new tab. If its difit server has stopped, the agent is asked to open it again'
  const materials = item.materials || []
  if (name === 'review' && materials.length) return `Open ${materials.map((material) => material.label).join(', ')} in one Safari tab group named "${item.tabGroup}", and move it to In Progress`
  if (name === 'review' && item.state === 'queued') return 'Nothing to open is recorded on it: asks its agent to open what it prepared, and moves it to In Progress'
  const help = buttonHelp(live ? 'note' : name, sectionName)
  const off = buttonOff(name, item, sectionName)
  return off ? `${help}. Not available yet: ${off}` : help
}

const pressStart = { queue: 'queuing…', review: 'opening the review in Safari…', block: 'blocking…', agent: 'starting an agent…', start: 'starting an agent…', note: 'sending your note…', open: 'asking the agent to open the review…', merge: 'merging…', answer: 'sending your answer…', requeue: 'moving it to Queued…', dismiss: 'hiding…' }

const pressSaid = (kind, reply) => {
  if (reply.unreachable) return 'no answer from the server, checking…'
  if (kind === 'queue' && reply.session) return `agent "${reply.session}" is preparing it; it lands in Queued when ready…`
  if (kind === 'queue' || kind === 'requeue') return 'moving it to Queued…'
  if (kind === 'review' && reply.tabGroup) return `${reply.opened === 'dry run, not opened' ? 'dry run, Safari not opened' : 'opened in Safari'}: tab group "${reply.tabGroup}" with ${(reply.urls || []).length} page${(reply.urls || []).length === 1 ? '' : 's'}${reply.delivery ? ', the agent is starting the app and difit' : ''}…`
  if (kind === 'block') return 'blocked, telling the assistant…'
  if (reply.session) return `session "${reply.session}" started, waiting for it to report in…`
  if (kind === 'merge') return 'GitHub took the merge, waiting for it to show as merged…'
  if (reply.delivery === 'delivered') return 'delivered to the agent, waiting for it to pick it up…'
  if (reply.delivery === 'queued') return 'queued: the agent is busy and gets it when its turn ends…'
  if (reply.delivery === 'queued for its terminal session') return 'saved, not delivered: its session is open in a terminal, so it is queued until that session reads the card or ends…'
  if (reply.delivery === 'queued until its terminal tab closes') return 'queued: the assistant is open in a Ghostty tab and will pick this up shortly…'
  if (reply.delivery === 'relayed through the assistant, queued until its terminal tab closes') return 'queued: passed to the assistant, which is open in a Ghostty tab and will pick this up shortly…'
  if (/^relayed through the assistant, queued/.test(reply.delivery || '')) return 'queued: passed to the assistant, which gets it when its turn ends or its Ghostty tab closes…'
  if (reply.delivery === 'relayed through the assistant') return 'the agent is busy: passed on through the assistant, waiting for it to pick it up…'
  return ''
}

const pressSeen = (record, item, sectionName, hidden) => {
  const agent = item ? item.agent : null
  const moved = Boolean(agent) && ((Boolean(agent.heartbeat) && Date.parse(agent.heartbeat) > record.at) || (agent.doing || null) !== record.doing)
  const telling = agent && agent.doing ? `: ${agent.doing}` : ''
  if (record.kind === 'queue') return item && item.state === 'preparing' ? `an agent is preparing it${telling}` : item && item.state === 'queued' ? 'in Queued' : ''
  if (record.kind === 'review') return item && item.state === 'in-progress' ? `in progress: ${record.said ? record.said.replace(/…$/, '') : 'review opened'}` : ''
  if (record.kind === 'block') return item && item.state === 'blocked' ? 'blocked: the assistant was told' : ''
  if (record.kind === 'requeue') return item && item.state === 'queued' ? 'in Queued' : ''
  if (record.kind === 'dismiss') return hidden ? 'dismissed' : ''
  if (record.kind === 'agent' || record.kind === 'start') return agent && !['done', 'stopped'].includes(agent.state) && Date.parse(agent.since) > record.at - 5000 ? `agent "${agent.session}" is working${telling}` : ''
  if (record.kind === 'note') return moved ? `the agent got your note${telling}` : ''
  if (record.kind === 'open') return agent && agent.state === 'reviewing' ? `the review ${record.already ? 'is already' : 'is'} open${telling}` : ''
  if (record.kind === 'answer') return item && item.question && !item.question.answer ? '' : !item || !item.question || moved ? `the agent has your answer${telling}` : ''
  if (record.kind === 'merge') return !item || sectionName !== record.section ? 'merged' : ''
  return ''
}

const pressLimit = (record) => {
  if (record.kind === 'agent' || record.kind === 'start' || record.kind === 'merge') return 60000
  return /queued|busy/.test(record.said || '') ? 300000 : 90000
}

const pressLateBad = (record, item) => !record.said || Boolean(record.noAnswer) || Boolean(item && item.agent && item.agent.state === 'stopped')

const pressLate = (record, item) => {
  const clock = new Date(record.at).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }).toLowerCase()
  if (item && item.agent && item.agent.state === 'stopped') return `the agent stopped before showing it picked this up: open it in a terminal`
  if (record.noAnswer) return record.kind === 'agent' || record.kind === 'start' ? 'no answer from the server and no agent started · retry' : 'no answer from the server and nothing changed · retry'
  if (record.kind === 'agent' || record.kind === 'start') return record.said ? `session started ${clock} · it has not reported in yet` : 'no session started: press again or check the robot menu'
  if (record.kind === 'merge') return `GitHub took the merge ${clock} · not showing as merged yet; the sync arrows read GitHub again`
  return `delivered ${clock} · no update from the agent yet`
}
