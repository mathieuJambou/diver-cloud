Describe "New-ResourceGroup" {
    $location = 'eastus2'
    $name = 'cloudskillsbootcamp'

    It "Name should be cloud" {
        $name | Should Be 'cloud'
    }

    It "location should be eastus2" {
        $location | Should Be 'eastus2'
    }
}