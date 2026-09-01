<script lang="ts">
	import { getContext } from 'svelte';
	import Modal from '$lib/components/common/Modal.svelte';

	const i18n = getContext('i18n');

	export let show = false;
	export let onClose = () => {};

	const close = () => {
		show = false;
		onClose();
	};
</script>

<Modal bind:show size="xl" className="bg-white dark:bg-gray-900 rounded-2xl">
	<div class="faq flex flex-col max-h-[85vh]">
		<div
			class="flex items-center justify-between px-6 pt-5 pb-3 shrink-0 border-b border-gray-50 dark:border-gray-850"
		>
			<div class="text-lg font-medium text-gray-900 dark:text-white">
				{$i18n.t('Frequently Asked Questions')}
			</div>
			<button
				class="p-1 rounded-full text-gray-500 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-400 dark:hover:text-white dark:hover:bg-gray-800 transition"
				on:click={close}
				aria-label={$i18n.t('Close')}
			>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 20 20"
					fill="currentColor"
					class="size-5"
				>
					<path
						d="M6.28 5.22a.75.75 0 0 0-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 1 0 1.06 1.06L10 11.06l3.72 3.72a.75.75 0 1 0 1.06-1.06L11.06 10l3.72-3.72a.75.75 0 0 0-1.06-1.06L10 8.94 6.28 5.22Z"
					/>
				</svg>
			</button>
		</div>

		<div class="px-6 py-3 overflow-y-auto text-sm text-gray-700 dark:text-gray-300">
			<!-- Section 1 -->
			<div class="faq-eyebrow">How AI Arcade Works &amp; Your Data</div>

			<details open>
				<summary>How does AI Arcade work, and how is my data protected?</summary>
				<div class="faq-a">
					<p>
						AI Arcade is Rancho's internal AI platform, built on Open WebUI. Your conversations and
						uploaded files are stored securely within Rancho's own environment and remain governed
						by the company's privacy policies. Open WebUI does not collect your data or use it to
						train any AI models.
					</p>
					<p>
						When you send a message, it is transmitted through Rancho's secured connection to the AI
						provider solely to generate your response. Under the provider's API terms, your data is
						not used to train their models.
					</p>
					<p>
						Because these protections are built into Arcade, it offers stronger data security than
						personal or public AI accounts, where conversations may be stored or used to train
						models.
					</p>
				</div>
			</details>

			<details>
				<summary>Should I redact sensitive information before uploading documents?</summary>
				<div class="faq-a">
					<p>
						As an extra precaution, yes. Even though Arcade is secured, it is good practice to
						redact or replace sensitive details before uploading documents. Information such as
						client names, figures, or costs can be swapped for placeholders such as <span
							class="faq-pill">XXX</span
						>. This adds a further layer of protection for confidential information.
					</p>
				</div>
			</details>

			<!-- Section 2 -->
			<div class="faq-eyebrow">Data, Privacy &amp; Security</div>

			<details>
				<summary>Can I use confidential or client data with AI Arcade?</summary>
				<div class="faq-a">
					<p>
						Not without proper authorization. Client data must not be used with any AI tool,
						including internal Rancho tools, unless the client has explicitly given permission.
						Before using AI Arcade with client data:
					</p>
					<ul>
						<li>
							<strong>Client preferences matter.</strong> Clients may have preferred AI tools or restrictions,
							and their policies must be respected.
						</li>
						<li>
							<strong>Check what was agreed upfront.</strong> Confirm whether AI use was discussed and
							documented when the project was set up.
						</li>
						<li>
							<strong>Contact your Project Manager.</strong> If you are unsure of the client's AI preferences
							or the arrangement in place, check with your PM before proceeding.
						</li>
						<li>
							<strong>Internal requirements still apply.</strong> Even with client permission, AI tools
							must be used within Rancho-approved, secure environments (such as AI Arcade) that have passed
							IT Security review for encryption, access controls, data retention, and audit logging.
						</li>
					</ul>
					<p>
						When in doubt, do not use client data with any AI tool until the appropriate permissions
						are confirmed.
					</p>
				</div>
			</details>

			<details>
				<summary>Can I put my personal information into AI Arcade?</summary>
				<div class="faq-a">
					<p>
						No. Do not enter personal information into any internal AI tool. This includes, but is
						not limited to, medical information, financial details, Social Security numbers, or any
						other personally identifiable information (PII). The company does not want to hold
						employee PII beyond what is strictly necessary for business operations.
					</p>
				</div>
			</details>

			<details>
				<summary>Does AI Arcade use our data to train its models?</summary>
				<div class="faq-a">
					<p>
						No. Data processed through Rancho AI systems is not used for model training without
						explicit written authorization.
					</p>
				</div>
			</details>

			<!-- Section 3 -->
			<div class="faq-eyebrow">Accountability &amp; Oversight</div>

			<details>
				<summary>Who is responsible for the accuracy of AI-generated outputs?</summary>
				<div class="faq-a">
					<p>
						You are. Users are personally accountable for verifying that AI outputs are accurate,
						complete, and fit for their intended purpose. AI never replaces human judgment, and
						users are responsible for any AI-assisted work they submit.
					</p>
				</div>
			</details>

			<details>
				<summary>Who oversees AI usage at Rancho BioSciences?</summary>
				<div class="faq-a">
					<p>
						The RAISE (Rancho AI Steering and Enablement) Team governs all AI strategy, tool
						approvals, standards, and incident management, under authority delegated from the
						Executive Leadership Team (ELT).
					</p>
				</div>
			</details>

			<details>
				<summary>What data policies govern AI usage?</summary>
				<div class="faq-a">
					<p>
						All AI activity must comply with Rancho's Data Protection and Privacy Policy (<span
							class="faq-pill">RPOL-DAT-05</span
						>) and the Comprehensive Data and Systems Security Policy (<span class="faq-pill"
							>RPOL-DAT-01</span
						>).
					</p>
				</div>
			</details>

			<!-- Section 4 -->
			<div class="faq-eyebrow">Compliance, Reporting &amp; Support</div>

			<details>
				<summary
					>What should I do if I suspect an AI-related security or compliance incident?</summary
				>
				<div class="faq-a">
					<p>
						Report it immediately to IT Security or RAISE. Prompt reporting is critical to limiting
						risk.
					</p>
				</div>
			</details>

			<details>
				<summary>What happens if someone violates the AI policy?</summary>
				<div class="faq-a">
					<p>Violations may result in disciplinary action, up to and including termination.</p>
				</div>
			</details>
		</div>
	</div>
</Modal>

<style>
	.faq-eyebrow {
		font-size: 0.7rem;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		font-weight: 600;
		color: #1f5941;
		margin: 18px 0 6px;
	}
	:global(.dark) .faq-eyebrow {
		color: #4fa484;
	}
	.faq details {
		border-bottom: 1px solid rgb(0 0 0 / 0.06);
	}
	:global(.dark) .faq details {
		border-bottom-color: rgb(255 255 255 / 0.08);
	}
	.faq summary {
		cursor: pointer;
		list-style: none;
		padding: 12px 30px 12px 0;
		position: relative;
		font-weight: 500;
		color: inherit;
	}
	.faq summary::-webkit-details-marker {
		display: none;
	}
	.faq summary::after {
		content: '';
		position: absolute;
		right: 8px;
		top: 50%;
		width: 8px;
		height: 8px;
		border-right: 1.5px solid currentColor;
		border-bottom: 1.5px solid currentColor;
		transform: translateY(-70%) rotate(45deg);
		opacity: 0.5;
		transition: transform 0.2s ease;
	}
	.faq details[open] summary::after {
		transform: translateY(-30%) rotate(225deg);
	}
	.faq-a {
		padding: 0 0 14px;
		color: rgb(0 0 0 / 0.62);
	}
	:global(.dark) .faq-a {
		color: rgb(255 255 255 / 0.6);
	}
	.faq-a p {
		margin: 0 0 10px;
	}
	.faq-a p:last-child {
		margin-bottom: 0;
	}
	.faq-a ul {
		margin: 6px 0 10px;
		padding-left: 18px;
		list-style: disc;
	}
	.faq-a li {
		margin: 6px 0;
	}
	.faq-a strong {
		color: inherit;
		font-weight: 600;
	}
	.faq-a a {
		color: #1f5941;
		text-decoration: underline;
	}
	:global(.dark) .faq-a a {
		color: #4fa484;
	}
	.faq-pill {
		font-family: ui-monospace, monospace;
		font-size: 0.85em;
		background: rgb(0 0 0 / 0.05);
		padding: 1px 6px;
		border-radius: 4px;
	}
	:global(.dark) .faq-pill {
		background: rgb(255 255 255 / 0.08);
	}
</style>
