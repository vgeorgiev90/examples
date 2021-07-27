import https from 'k6/http';
import { sleep, check } from 'k6';
import { Rate } from 'k6/metrics';


const BASE_URL = 'https://app.aws.myauditlab.com';

const FailRate = new Rate('failed requests');



export let options = {
  insecureSkipTLSVerify: true,
  stages: [
    { duration: '10m', target: 30 }, // 300 users for 10 minutes
  ],
  thresholds: {
    http_req_duration: ['p(99)<500'], // 99% of requests must complete below 500ms
    'failed requests': ['rate<0.1'],
  }
};


export default function () {
  // Checks are based on: https://bitbucket.org/cobrowser/cb_kubernetes/src/develop/doc/private-cloud-environments.md
  // check main page
  let response = https.get(`${BASE_URL}`);
  check(response, {
	  'is status 200': (r) => r.status === 200,
  });
  FailRate.add(response.status !== 200);

  sleep(1);
}

