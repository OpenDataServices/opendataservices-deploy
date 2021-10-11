import ijson
import json
import os
import traceback
from decimal import Decimal


# We assmue that there are no one-to-many relationships besides location
def one_to_one_assumption(l):
    for x in l:
        if type(x) == list:
            if len(x) == 2 and x[0] == x[1]:
                print('WARNING, Duplicate lines')
            else:
                assert len(x) <= 1
            one_to_one_assumption(x)
        elif type(x) == dict:
            one_to_one_assumption(x.values())
        else:
            # Check we've not got the wrong types above
            assert type(x) in [str, type(None), bool, int, Decimal]

# We assume that all of a funder's grants are from the same publisher.
publisher_by_funder = {}
def funders_grants_same_publisher(grant, publisher):
    funder = grant['fundingOrganization'][0]['id']
    if funder in publisher_by_funder:
        try:
            assert publisher['prefix'] == publisher_by_funder[funder]
        except:
            print(publisher['prefix'], publisher_by_funder[funder])
            raise
    else:
        publisher_by_funder[funder] = publisher['prefix']
        

def check_grant_assumptions(grant, dataset):
    one_to_one_assumption(grant.values())
    funders_grants_same_publisher(grant, dataset['publisher'])


publisher_access_urls = {}
with open('data/data_valid.json') as fp:
    data_json = json.load(fp)
for dataset in data_json:
    print('Checking {}: {} ({})'.format(dataset['publisher']['name'], dataset['title'], dataset['identifier']))

    # We assume that all publishers have a non-empty prefix 
    prefix = dataset['publisher']['prefix']
    assert prefix
    # We assume that each dataset has one distribution
    assert len(dataset['distribution'])
    distribution =  dataset['distribution'][0]

    # AccessURL should start with http:// or https://
    assert distribution['accessURL'].startswith('http://') or distribution['accessURL'].startswith('https://')
    # Website should start with http:// or https://
    assert dataset['publisher']['website'].startswith('http://') or dataset['publisher']['website'].startswith('https://')

    ## We assume that all datasets from one publisher have the same:
    ##   - accessURL
    # This check is CURRENTLY DISABLED, as we know there are now some exceptions to this rule
    # They don't display amazingly on GrantNav atm, but this is a traedoff we've chosen to make
    # See internal issue https://opendataservices.plan.io/issues/12170#note-17
    #if prefix in publisher_access_urls:
    #    assert distribution['accessURL'] == publisher_access_urls[prefix]
    #else:
    #    publisher_access_urls[prefix] = distribution['accessURL']

    try:
        with open(os.path.join('data/json_all/{}.json'.format(dataset['identifier']))) as fp:
            stream = ijson.items(fp, 'grants.item')
            for grant in stream:
                try:
                    if 'location' in grant['recipientOrganization'][0]:
                        assert len(grant['recipientOrganization'][0]['location']) <= 2
                    grant['recipientOrganization'][0]['location'] = None
                    if 'beneficiaryLocation' in grant:
                        assert len(grant['beneficiaryLocation']) <= 8
                    grant['beneficiaryLocation'] = None
                    grant['classifications'] = None
                    check_grant_assumptions(grant, dataset)
                except:
                    print(grant)
                    raise
    except KeyboardInterrupt:
        raise
    except:
        traceback.print_exc()
        continue


# TODO: check that grant ids start with prefixes
